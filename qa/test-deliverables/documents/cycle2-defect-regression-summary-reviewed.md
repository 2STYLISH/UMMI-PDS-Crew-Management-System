# UMMI Crew Management System — Cycle 2 Defect & Regression Summary (Reviewed Edition)

> **Document Status:** Authoritative Reviewed Edition (Reconciled with Authoritative Workbook `Lists` Register and Uploaded SRS)  
> **Authoritative SRS Baseline:** [`documents/ByteMe SRS - UMMI.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/ByteMe%20SRS%20-%20UMMI.docx) (1,422,993 bytes | SHA-256: `96b220779905dd31f49083ad6606398812269825d4d0200a2657a0bca950ed45`)  
> **Authoritative Workbook with RTM:** [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Contains dedicated `RTM` tab with 11 columns)  
> **Authoritative Execution Workbook:** [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Worksheet: `Lists`, Rows 37–79)  
> **Authoritative Defect Register:** `DEF-CM-001` through `DEF-CM-020` (20 Defect Records)  
> **Active Open Defects:** **1 Open Defect (`DEF-CM-020`)** | **19 Resolved & Verified Defects**  
> **Target Staging Environment:** Azure App Service (`Southeast Asia`) | IIS 10.0 | ASP.NET 4.0 | MySQL 8.0  
> **Superseded Prior Document:** `qa/test-deliverables/documents/cycle2-defect-regression-summary.md` (Retained unchanged for audit history)

---

## 1. Executive Summary & Defect Lifecycle Metrics

During Cycle 2 verification and retesting of the UMMI Crew Management System, a total of **20 application defects (`DEF-CM-001` through `DEF-CM-020`)** were formally cataloged, tracked, and evaluated against deployed Azure staging builds.

### Complete Status Accounting
- **Total Cataloged Defects:** **20**
- **Resolved and Verified:** **19 (95.0%)**
- **Open Defect:** **1 (5.0%) — `DEF-CM-020`** (Ongoing Sea Service Operational Date / UTC Inferred Fallback)
- **Recurred / Regressed Defects During Testing:** 3 (`DEF-CM-008` blank popup names, `DEF-CM-010` AI runtime error, `DEF-CM-016` vessel grouping header recurrence)
- **Documented Technical Limitations / Outstanding Evidences:** **3** (`EVD-CM-001`, `EVD-CM-002`, `QA-CM-001`)
- **Environment Incidents:** **2** (`INC-CM-001` Azure F1 load quota, `INC-CM-002` synthetic assessment PDF fixture)

---

## 2. Complete Authoritative Defect Register (DEF-CM-001 to DEF-CM-020)

| Defect ID | Test Case(s) | Module / Area | Defect Summary & Occurrence | Severity | Status | Fix / Commit Deployed | Retest Outcome & Evidence |
| :--- | :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| **DEF-CM-001** | `TC-CM-028` | Crew Search | Assigned-vessel filtering returned an incorrect or stale result set. *(New)* | Medium | **Resolved** | Azure Staging build `cb9df6c` | **Passed:** Synthetic vessel search verified via Playwright DOM assertions in `results.json`. |
| **DEF-CM-002** | `TC-CM-043` | Crew Search / Auth | `btnExportExcel` remained visible and callable for Vessel Owner on postback. *(New)* | High | **Resolved** | `cb9df6c` (`QueryCrew.aspx.vb` role guard check) | **Passed:** Export button hidden in DOM on initial load and postback in `four-fix-rerun-results.json`. |
| **DEF-CM-003** | `TC-CM-163..167` | Applicant Link | Malformed, expired, or used tokens entered redirect loop or lacked denial audit log. *(New)* | High | **Resolved** | `cb9df6c` / `26d03d7` | **Passed:** Immediate redirect to `AccessDenied.aspx` and sanitized audit log confirmed in `targeted-regression-results.json`. |
| **DEF-CM-004** | `TC-CM-188; 221` | Documents / Auth | Unauthorized users could retrieve files directly from `/Uploads/documents/`. *(New)* | High | **Resolved** | `d27298b` / `c737536` (`Web.config` forbidden handler) | **Passed:** Static requests return HTTP 404/403 block in `fig19-tc221-direct-static-file-404-block.png`. |
| **DEF-CM-005** | `TC-CM-188; 221` | Document Handler | Filename fallback could resolve an ambiguous record or serve file from another crew folder. *(New)* | High | **Resolved** | `c737536` (`CrewDocumentHandler.ashx`) | **Passed:** Direct ID resolution and strict crew ownership guard confirmed in `fig18-tc221-protected-handler-document-view.png`. |
| **DEF-CM-006** | `TC-CM-103..218` | Activity Logging | Activity-log assertions failed due to timestamp format mismatch in `AuditHelper.vb`. *(New)* | Medium | **Resolved** | `26d03d7` / `cb9df6c` | **Passed:** Verified structured logging across 11 test cases in `targeted-regression-summary.md`. |
| **DEF-CM-007** | `TC-CM-201` | CCL / EOC | Cancelling a finalized schedule displayed `No EOC` instead of approved cancelled state. *(New)* | Medium | **Resolved** | `cb9df6c` | **Passed:** Grid displays approved `Superseded` status in `fig11-ccl-scheduling-lifecycle-regression.png`. |
| **DEF-CM-008** | `CCL-POPUP` | CCL Scheduling | Create Schedule and Edit Schedule popups displayed blank outgoing crew name. *(Regressed)* | High | **Resolved** | `c737536` | **Passed:** Popups correctly bind outgoing crew identity in `fig12-ccl-create-schedule-names-verified.png`. |
| **DEF-CM-009** | `TC-CM-212` | AI Suggestion | Scalar AI suggestions lacked an explicit Reject / Dismiss control. *(New)* | Medium | **Resolved** | Commit `b323bcd` (Redeployed `97fd151`) | **Passed:** Explicit Reject button rendered on all scalar inputs in `tc212-final-retest-summary.md`. |
| **DEF-CM-010** | `TC-CM-212` | AI Suggestion | Clicking scalar Reject button caused runtime `TypeError: this.saveState is not a function`. *(Regressed)* | High | **Resolved** | Commit `b323bcd` (Redeployed `97fd151`) | **Passed:** Method calls aligned to `recordFieldDecision`; zero runtime errors in `fig15-tc212-apply-replace-edit-verified.png`. |
| **DEF-CM-011** | `TC-CM-096` | Sea Service | Culture-dependent date parsing and overlapping service produced erroneous totals. *(New)* | Medium | **Resolved** | Build `d27298b` | **Passed:** Culture-invariant parsing and interval merging confirmed in `fig07-tc096-sea-service-overlap-verified.png`. |
| **DEF-CM-012** | `TC-CM-186` | Credential Security | Legacy password storage used single-round general SHA-256 without adaptive work factor. *(New)* | High | **Resolved (w/ Lim)** | Staging baseline | **Passed with Limitation:** PBKDF2 with 100k rounds verified in code/fixtures (`fig17-tc186-login-generic-error-pbkdf2.png`). Live row audit pending (`EVD-CM-001`). |
| **DEF-CM-013** | `TC-CM-203` | CCL Sign-On | Required manual sign-on path for recording assigned vessel and ON BOARD status was unavailable. *(New)* | High | **Resolved** | Build `d27298b` | **Passed:** Manual sign-on modal and state transition verified in `fig08-tc203-manual-crew-sign-on-modal.png`. |
| **DEF-CM-014** | `CCL-RELIEVER` | Reliever Search | Eligible On Vacation crew (Status 4) were omitted from the reliever pool. *(New)* | Medium | **Resolved** | Build `d27298b` (`CCLHelper.vb`) | **Passed:** Expanded filter query confirmed in `fig10-ccl-reliever-search-pool-modal.png`. |
| **DEF-CM-015** | Build / Master | Master Page | `divNavApplicantPool` was missing from designer declaration, causing compiler failure. *(Regressed)* | High | **Resolved** | Cycle 2 Phase 1 build | **Passed:** Added server-side HTML generic control declaration; compilation verified. |
| **DEF-CM-016** | `TC-CM-050` | Crew Search | Vessel grouping headers missing in earlier run; flat GridView observed. *(Recurred)* | Medium | **Resolved** | Live staging retest | **Passed:** Inline vessel group headers verified in `fig01-tc050-all-vessels-visual-grouping.png`. |
| **DEF-CM-017** | `TC-CM-076` | Profile / BMI | BMI display omitted approved one-decimal precision, displaying raw integers. *(New)* | Medium | **Resolved** | Live staging retest | **Passed:** Display preserves one decimal (e.g., `22.4`) in `fig01-tc076-bmi-a001-normal.png`. |
| **DEF-CM-018** | `TC-CM-098` | Sea Service | Crew Search and Profile Viewer displayed differing sea-service totals (1.7 yr vs 4.1 yr). *(New)* | Medium | **Resolved** | Live staging retest | **Passed:** Interval merging and source query alignment verified in both views. |
| **DEF-CM-019** | `TC-CM-074` | Profile / Auth | Vessel Owner could view an unassigned crew profile via direct URL tampering. *(New)* | High | **Resolved** | ETag `0ddb838859dd1:0` | **Passed:** Direct vessel assignment guard verified; unassigned crew access denied in `evidence/Cycle2/TC-CM-074/screenshots/`. |
| **DEF-CM-020** | `TC-CM-098` | Ongoing Sea Service | Ongoing service used a date one day behind Philippine operational date (UTC date fallback inferred). *(New)* | Medium | **OPEN / FAILED** | **Pending Development Fix** | **FAILED:** Lucas 252 contract 6 displayed `0.4 yr(s)` instead of expected `0.5 yr(s)` on Oct 11 06:18 PHT. 164 days matched the previous UTC calendar date; UTC `CURDATE()` fallback is inferred as a working hypothesis (application pooled-session timezone was not directly captured). Retest required. |

---

## 3. Preserved Operational Limitations & Incident Log

All documented limitations from the authoritative workbook (`QA TEST PLAN UMMI.xlsx`) are preserved with exact technical scoping:

### Evidence & Assurance Limitations
- **`EVD-CM-001` (TC-CM-186 — Stored Credential Audit):**
  - *Status:* **Passed with Technical Limitation**
  - *Detail:* Adaptive PBKDF2 hashing (100,000 iterations) is verified in application source code, login flows, and synthetic database setups. Direct read-only query inspection of live deployed staging rows was blocked by Azure Database for MySQL firewall rules.
- **`EVD-CM-002` (TC-CM-228 — Third-Party AI Provider Controls vs. Optional Formats):**
  - *Status:* **Passed with Technical Limitation**
  - *Required Provider Controls (SRS SR-11 & SR-13):* The system shall send only required document information, shall use encryption in transit/rest, and the provider shall not retain submitted content or use it for training. These technical controls passed via API payload minimalism, HTTPS transport, and transient request configurations.
  - *Optional Certification / Document Formats:* Formal contractual third-party documents (such as a specific Data Processing Agreement or SOC 2 certification from DeepInfra) were not archived. These are optional audit verification formats rather than mandatory document formats stipulated by the current SRS text.
- **`QA-CM-001` (TC-CM-222 — Atomic Transaction Rollback):**
  - *Status:* **Unverified**
  - *Detail:* Verification of atomic rollback across personnel records, document linkages, and file storage during mid-transaction failures requires an isolated fault-injection environment not safe to execute against the shared Azure staging environment.

### Environment Incidents
- **`INC-CM-001` (TC-CM-182 — Azure Free Tier Data Out Quota):**
  - *Status:* **Deferred / Partially Passed**
  - *Detail:* Azure Free F1 staging tier halted load testing after 5 minutes 39 seconds of sustained 100-user traffic due to exceeding the daily 509.74 MiB Data Out quota (590.87 MiB consumed). CPU time remained nominal (12.63 of 60 mins). Staging tier scale-up is required before official certification load runs.
- **`INC-CM-002` (TC-CM-068 / 074 — Staging Assessment PDF Fixture):**
  - *Status:* **Resolved / Passed**
  - *Detail:* Physical synthetic assessment PDF was missing on staging storage, returning HTTP 404. Restored under `/Uploads/assessments/` via manual Kudu deployment.

### Requirement Clarifications & Acceptance Baseline Changes
- **`REQ-CM-002` (TC-CM-077 — BMI Classification Gaps):**
  - *SRS Baseline:* `FR-CM-13` explicitly defines numeric classification thresholds: Underweight (< 18.5), Normal (18.5 to < 25), Overweight (25 to < 30), and Obese (>= 30), with one-decimal display and suppression of blank/zero inputs.
  - *Remaining Gaps:* TC-CM-077 remains **Blocked** due to:
    1. Unconfirmed evaluation basis at cutoffs: whether classification evaluates raw floating-point BMI or rounded 1-decimal display values at exact boundaries (e.g., 24.95 -> 25.0).
    2. Undefined UI badge palette: approved background/text colors for status badges are not specified in the SRS.
    3. Missing test fixtures: synthetic test records positioned directly at lower/upper cutoffs (18.49/18.50, 24.99/25.00, 29.99/30.00) have not been provisioned.
- **`REQ-CM-003` (TC-CM-169 — Exact Expiry Equality Boundary):** Decision on exact-timestamp boundary equality at link expiry remains pending. Status: **Partially Passed**.
- **`REQ-CM-004` (TC-CM-074 — Vessel Owner Dropdown Scope):** Vessel Owner dropdown renders all vessels rather than filtering to assigned vessels in the selection UI (though profile navigation is guarded). Status: **Unverified UI Rule**.
- **`REQ-CM-005` (TC-CM-184 / 185 — Obsolete Role Alignment):** Formal removal of client/supplier terminology and supplier approval from specification baseline. Status: **Out of Scope (185) / Passed (184)**.

---

## 4. Cross-Reference Mapping: Legacy Aliases vs. Authoritative IDs

Earlier summary drafts and screenshot captions utilized informal working aliases (`DEF-01` through `DEF-07`). The table below provides the definitive bidirectional translation:

| Legacy Draft ID | Authoritative Register ID | Test Case(s) | Primary Subject Matter |
| :---: | :---: | :---: | :--- |
| `DEF-01` | **`DEF-CM-002`** | `TC-CM-043` | Vessel Owner Export Excel button visibility in `QueryCrew.aspx.vb`. |
| `DEF-02` | **`DEF-CM-006`** | `TC-CM-103, 104, 144, 160, 164..167, 204, 218` | `AuditHelper.vb` timestamp format logging failures. |
| `DEF-03` | **`DEF-CM-007`** | `TC-CM-201` | Cancelled CCL Schedule EOC display (`No EOC` vs `Superseded`). |
| `DEF-04` | **`DEF-CM-008`** | `TC-CM-189..202` (Popups) | Blank outgoing crew name in CCL schedule popups. |
| `DEF-05` | **`DEF-CM-009`** | `TC-CM-212` | Missing scalar Reject / Dismiss button in AI suggestion review. |
| `DEF-06` | **`DEF-CM-010`** | `TC-CM-212` | JavaScript runtime exception (`this.saveState is not a function`). |
| `DEF-07` | **`DEF-CM-004` / `DEF-CM-005`** | `TC-CM-188`, `TC-CM-220`, `TC-CM-221` | Protected document handler 404 and static file directory block. |
| *Unmapped in draft* | **`DEF-CM-011`** | `TC-CM-096` | Sea service date culture parsing and overlapping service intervals. |
| *Unmapped in draft* | **`DEF-CM-012`** | `TC-CM-186` | PBKDF2 adaptive credential storage upgrade. |
| *Unmapped in draft* | **`DEF-CM-013`** | `TC-CM-203` | Manual crew sign-on workflow and On Board status update. |
| *Unmapped in draft* | **`DEF-CM-014`** | `CCL-RELIEVER` | Inclusion of On Vacation (Status 4) in reliever nomination pool. |
| *Unmapped in draft* | **`DEF-CM-015`** | Master Page | Designer declaration for `divNavApplicantPool` control. |
| *Unmapped in draft* | **`DEF-CM-016`** | `TC-CM-050` | Recurred crew search vessel grouping headers. |
| *Unmapped in draft* | **`DEF-CM-017`** | `TC-CM-076` | One-decimal BMI numeric formatting. |
| *Unmapped in draft* | **`DEF-CM-018`** | `TC-CM-098` | Discrepancy between Crew Search and Profile sea-service totals. |
| *Unmapped in draft* | **`DEF-CM-019`** | `TC-CM-074` | Vessel Owner unassigned profile direct URL parameter tampering. |
| *Unmapped in draft* | **`DEF-CM-020`** | `TC-CM-098` | **OPEN:** Ongoing sea service Philippine operational date calculation (UTC fallback inferred). |

---
*Reviewed and codified in accordance with authoritative QA delivery governance.*
