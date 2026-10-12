# QA Test Deliverables — Documentation Reconciliation & Corrections Log (CORRECTIONS.md)

> **Execution Date:** October 12, 2026  
> **Package Location:** `qa/test-deliverables/`  
> **Repository:** `UMMI-PDS-Crew-Management-System`  
> **QA Branch:** `04-10_Perez_Cycle2-QA-Retest`  
> **Authoritative Baseline SRS:** [`documents/ByteMe SRS - UMMI.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/ByteMe%20SRS%20-%20UMMI.docx) (1,422,993 bytes | SHA-256: `96b220779905dd31f49083ad6606398812269825d4d0200a2657a0bca950ed45`)  
> **Authoritative Workbook with RTM:** [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Contains dedicated 11-column `RTM` tab)  
> **Purpose:** Authoritative reconciliation of packaged QA deliverables against the uploaded SRS and evidence workbook without overwriting original files, rerunning tests, or altering test results.

---

## 1. Authoritative Deliverables & Workbooks Inventory

In accordance with strict delivery governance, all original packaged documents and workbooks have been preserved untouched. A new copy of the authoritative workbook containing the new `RTM` worksheet has been created, and reviewed revisions of deliverables have been generated alongside the originals:

| Authoritative Deliverable | Packaged Path | Purpose & Corrections Applied |
| :--- | :--- | :--- |
| **Authoritative Uploaded SRS** | [`documents/ByteMe SRS - UMMI.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/ByteMe%20SRS%20-%20UMMI.docx) | Packaged locally in QA deliverables (1.42 MB, SHA-256 `96b22077...`). Defines 79 Functional Requirements (`FR-CM-01..79`), 17 active Security Rules (`SR-01..18`), 28 Use Cases (`UC-CM-01..28`), and 8 Performance Requirements (`PR-01..08`). |
| **Revised Software Test Plan** | [`documents/TEST PLAN UMMI-PDS.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/TEST%20PLAN%20UMMI-PDS.docx) | Revised Software Test Plan document (Version 2, 265 KB, updated October 12, 2026, Approver: Jeross Reilan R. Perez). |
| **Authoritative Workbook with RTM Tab** | [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) | Authoritative QA workbook containing dedicated **`RTM` tab** with 11 standardized columns, active internal hyperlinks to test rows and evidence entries, auto-filters, wrapped text, and frozen headers. Preserves all original sheets, formulas (110 formulas in Summary), and 250 drawing images. |
| **Original Defense Workbook (Historical Local)** | `qa/test-plan/TEST_PLAN_UMMI_DEFENSE_WITH_EVIDENCE.xlsx` | Original defense workbook without RTM tab (33.56 MB) preserved locally for historical reference and excluded from commit. |
| **Traceability Matrix (Reviewed)** | [`documents/cycle2-traceability-reviewed.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/cycle2-traceability-reviewed.md) | Encompasses all **229 distinct test cases** across Cycle 1 and Cycle 2 using latest result per case; aligns with uploaded SRS (`FR-CM-01..79`, `SR-01..18`, `UC-CM-01..28`, `PR-01..08`); preserves requirements with no explicit mapped tests (`SR-07`). |
| **Defect Summary (Reviewed)** | [`documents/cycle2-defect-regression-summary-reviewed.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/cycle2-defect-regression-summary-reviewed.md) | Catalogs the complete **`DEF-CM-001` through `DEF-CM-020` register**; preserves **Open Defect `DEF-CM-020`** (classifying UTC cause as an inference); accurately describes TC-CM-077 BMI evaluation/palette/fixture gaps; separates required provider controls from optional certification formats. |
| **Evidence Index (Reviewed)** | [`documents/cycle2-evidence-index-reviewed.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/cycle2-evidence-index-reviewed.md) | Resolves relative links to point to actual packaged paths (`../evidence/...`); catalogs all Cycle 2 cases; distinguishes visual screenshot cases (69 cases, 246 images) from headless telemetry cases (73 cases). |
| **Final QA Report (Reviewed)** | [`documents/cycle2-final-qa-report-reviewed.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/cycle2-final-qa-report-reviewed.md) | Reconciles metrics across all 229 distinct cases; clarifies that **no formal sign-off or final client UAT acceptance exists**; establishes conditional staging readiness for UAT review. |
| **SRS Status Note** | [`documents/SRS_STATUS_NOTE.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/SRS_STATUS_NOTE.md) | Updated to confirm the authoritative SRS is packaged locally at `documents/ByteMe SRS - UMMI.docx`. |

---

## 2. Specific Specification & Alignment Reconciliations

### A. Accurate Description of BMI Thresholds & TC-CM-077 Gaps
- **SRS Definition in `FR-CM-13`:**
  The uploaded SRS explicitly defines numeric Body Mass Index thresholds:
  - **Underweight:** Below `18.5`
  - **Normal:** From `18.5` to below `25.0`
  - **Overweight:** From `25.0` to below `30.0`
  - **Obese:** `30.0` or higher
  - **Formatting & Zero Suppression:** Display calculated BMI rounded to one decimal place; suppress calculation when height or weight is blank or zero.
- **TC-CM-077 Accurate Remaining Gaps:**
  `TC-CM-077` is classified as **Blocked** not because the SRS lacks numeric thresholds, but due to three specific engineering gaps:
  1. *Evaluation Basis at Cutoffs:* The SRS does not specify whether boundary classification evaluates raw floating-point BMI or rounded 1-decimal display values at exact cutoffs (e.g., whether `24.96` evaluates as Normal raw or Overweight rounded to `25.0`).
  2. *Badge Color Palette:* The approved UI badge palette (background and text color hex codes for Underweight, Normal, Overweight, Obese) is not defined in the SRS or design system.
  3. *Boundary Fixture Provisioning:* Controlled synthetic test crew records positioned precisely at cutoff boundaries (`18.49/18.50`, `24.99/25.00`, `29.99/30.00`) were not provisioned in staging.

### B. Separation of Required Provider Controls vs. Optional Certification Formats
- **Required Controls under SRS (`SR-11` & `SR-13`):**
  - Transit and at-rest encryption for uploaded documents and extracted data (`SR-11`).
  - Payload minimalism: send only required document fields to the processing provider (`SR-13`).
  - Provider shall not use applicant documents or extracted data for model training (`SR-13`).
  - Provider shall not retain submitted content after processing (`SR-13`).
  - Provider isolated behind an interchangeable service layer (`SR-13` / `SR-14`).
  *Verification Finding:* These mandatory technical controls are implemented and verified via transient API configurations and HTTPS network telemetry.
- **Optional Certification / Document Formats:**
  Formal vendor assurance documents (such as a specific Data Processing Agreement or SOC 2 certification from DeepInfra) are **optional governance verification formats**, not mandatory document formats stipulated by the SRS text. Lack of an archived DPA is an operational evidence limitation (`EVD-CM-002`), not an SRS violation.

### C. Complete 229-Case RTM Inventory (Cycle 1 + Cycle 2 Union)
- **Authoritative Inventory:** The full test repository consists of **229 distinct test cases** (191 in Cycle 1, 142 in Cycle 2, with 104 executed in both cycles):
  - **Passed (224 cases, 97.8%):** Latest result satisfied expected conditions (87 verified in Cycle 1 baseline; 137 verified in Cycle 2 retesting).
  - **Failed (1 case, 0.4%):** `TC-CM-098` failed ongoing sea service duration calculation (`DEF-CM-020`).
  - **Blocked (1 case, 0.4%):** `TC-CM-077` blocked on evaluation basis, palette, and boundary fixtures (`REQ-CM-002`).
  - **Out of Scope (2 cases, 0.9%):** `TC-CM-099` (extra PDS columns retired via `REQ-CM-006`) and `TC-CM-185` (supplier approval retired via `REQ-CM-005`).
  - **Unverified (1 case, 0.4%):** `TC-CM-222` unverified pending isolated database fault-injection (`QA-CM-001`).
- **Preserved Unmapped Requirements & Boundary Clarifications:**
  - `SR-07` (Audit Logging of Critical User Activities): In the uploaded SRS, `SR-07` requires logging critical user activities (profile views, hiring, link generation). In the workbook repository, it has **no mapped test case** and is labeled `No mapped test`. Furthermore, password complexity enforcement cannot be declared verified merely because strong passwords were used during administrative provisioning (`FIX-CM-001`). Dedicated negative validation testing remains an open gap.
  - `SR-03` (Supplier Account Approval): Formally retired from `ByteMe SRS - UMMI.docx`; `TC-CM-185` classified as Out of Scope.
  - `UC-CM-27` (Export Releasing Checklist): Mapped to `FR-CM-32` in SRS Use Case traceability, tested by `TC-CM-119`. Crew Change List operations are governed under `UC-CM-07` and `FR-CM-79` across test cases `TC-CM-189` through `TC-CM-204`.
  - `REQ-CM-001` (Super-Admin Bypass): Confirms that Super-Admin bypass of disabled per-user Crew Search / Applicant Pool settings is approved system behavior.

### D. Classification of DEF-CM-020 Root Cause as an Inference
- **Test Case:** `TC-CM-098` (Sea Service Ongoing Duration)
- **Observed Discrepancy:** Crew Lucas (ID 252, contract 6) displayed `0.4 yr(s)` instead of expected `0.5 yr(s)` on Oct 11 06:18 PHT.
- **Root Cause Classification:** **Inferred Working Hypothesis.**
  The calculated 164 days matches the previous UTC calendar date; fallback to a UTC `CURDATE()` evaluation is inferred. Direct application pooled-session timezone evidence (such as connection string session variables or IIS thread culture) was not captured during test execution.

---

## 3. Package Manifest & File Totals Reconciliation

`package_manifest.json` originally recorded 352 files. The physical directory tree currently contains 360 files. The breakdown is reconciled below:

| File Category | Manifest Record Count | Actual Disk Count | Reconciliation Analysis |
| :--- | :---: | :---: | :--- |
| **Pure Unchanged Copies** | 345 | 345 | Bit-for-bit SHA-256 match with repository sources (Playwright traces, raw screenshots, execution JSON telemetry). Source hash == Destination hash. |
| **Renamed Image Copies** | 240 (subset of 345) | 240 | Identical binary content, but renamed with test-case prefixes (`TC-CM-XXX_...`) during transfer. Bit-for-bit hash match preserved. |
| **Sanitized Reports** | 3 | 3 | Markdown files (`tc217`, `tc219`, `tc220`) were sanitized in `qa/playwright/evidence/` prior to packaging (passwords, IPs, PII replaced with generic hashes/tokens). Packaged copies match sanitized sources bit-for-bit. |
| **Pipeline-Generated Notes** | 2 | 2 | `documents/SRS_STATUS_NOTE.md` and `evidence/Cycle1/README.md` were generated during packaging (`src: N/A (Generated Compliance Note)`). |
| **Authoritative Workbook with RTM** | 0 | 1 | `documents/QA TEST PLAN UMMI.xlsx` (33.60 MB). Contains the new `RTM` tab with 304 mapping rows covering all 105 requirements and all 229 test cases, and 250 embedded images. |
| **Packaged Authoritative SRS** | 0 | 1 | `documents/ByteMe SRS - UMMI.docx` (1.42 MB, SHA-256 `96b22077...`). Uploaded baseline. |
| **Revised Software Test Plan** | 0 | 1 | `documents/TEST PLAN UMMI-PDS.docx` (265 KB). Uploaded revised test plan (Version 2). |
| **Consolidated Final Test Summary** | 0 | 1 | `documents/UMMI_FINAL_TEST_SUMMARY_REPORT.md`. Comprehensive Cycle 1 & 2 consolidation. |
| **Authoritative Reviewed Revisions** | 0 | 4 | `cycle2-traceability-reviewed.md`, `cycle2-defect-regression-summary-reviewed.md`, `cycle2-evidence-index-reviewed.md`, and `cycle2-final-qa-report-reviewed.md`. |
| **Package Index & Control Files** | 0 | 2 | `README.md` and `CORRECTIONS.md` (with bit-level SHA-256 records tracked in `package_manifest.json`). |
| **Total Reconciled Manifest Records** | **352** | **360** | **360 authoritative files tracked with bit-level SHA-256 hashes in `package_manifest.json`.** |

---

## 4. Formal Sign-Off & Release Recommendation Status

- **Formal Sign-Off Audit:** **No signed stakeholder acceptance certificates, independent test reports, or client UAT sign-offs exist.**
- **Authoritative Release Recommendation:** **NOT YET READY FOR RELEASE.** Based on recorded exit criteria:
  1. Remediation of open defect `DEF-CM-020` (PHT date calculation) remains incomplete.
  2. Load testing halted at 5m 39s due to Azure Free F1 daily bandwidth throttling (`TC-CM-182` / `INC-CM-001`).
  3. Verification of atomic mid-transaction rollback (`TC-CM-222` / `QA-CM-001`) remains unexecuted.
  4. Client stakeholder acceptance sign-off has not been obtained.
- **Staging Preview Availability Note:** The staging environment remains operational and conditionally available for internal stakeholder inspection and structured client UAT preview walkthroughs, provided all documented limitations are explicitly disclosed.

---
*Report prepared and recorded in accordance with authoritative QA delivery governance.*
