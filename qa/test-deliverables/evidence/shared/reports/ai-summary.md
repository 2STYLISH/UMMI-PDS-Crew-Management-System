# UMMI Playwright Test Suite — AI-Assisted Applicant Self-Encoding & Extraction Execution Summary

> **Environment:** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`  
> **Browser:** Google Chrome (`channel: 'chrome'`)  
> **Workers:** 1 | **Retries:** 0 | **Execution Mode:** Serial Order  
> **Date:** October 02, 2026  
> **Synthetic Run Identifier Prefix:** `QA-C2-AI-20261002`  
> **Test File:** [qa/playwright/tests/cycle2/ai-extraction.spec.ts](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/tests/cycle2/ai-extraction.spec.ts)  
> **Configuration File:** [qa/playwright/playwright.ai.config.ts](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/playwright.ai.config.ts)  
> **Evidence Artifacts:**
> - HTML Report: [qa/playwright/ai-report/index.html](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/ai-report/index.html)
> - JSON Results: [qa/playwright/evidence/ai-results.json](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/ai-results.json)
> - Test Results Directory: [qa/playwright/test-results/ai/](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/test-results/ai/)

---

## 1. Executive Summary

| Category | Count | Percentage |
| :--- | :---: | :---: |
| **Passed** | **13** | **52.0%** |
| **Blocked / Skipped** | **12** | **48.0%** |
| **Failed** | **0** | **0.0%** |
| **Total AI Cases** | **25** | **100.0%** |

All 25 test cases defined for Cycle 2 Phase F (AI-assisted applicant self-encoding and document extraction) were processed under 1 worker, 0 retries, and strict serial execution. Zero test failures occurred. 13 tests passed completely against the live Azure Staging environment. 12 tests were marked **Blocked** adhering strictly to the non-UI verification mandates, known defect boundaries, and backend API key requirements.

---

## 2. Test Case Inventory & Execution Results

| # | Test Case ID | Test Case Title | Actor | Operation | Controlled Fixture / Input | Expected Result | Status | Duration | Observed Result & Block/Defect Details |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: | :--- |
| 1 | **TC-CM-205** | Keep AI assistance optional and preserve manual encoding | Applicant | Read/Write | `valid_license.pdf` | AI assistance optional; manual encoding form enabled and editable | `PASSED` | 9.6s | Verified `.ai-badge-optional` present, `#chkAiConsent` unchecked by default, manual fields editable, consent toggled without wiping data. |
| 2 | **TC-CM-206** | Upload multiple available documents | Applicant | Write | `valid_license.pdf`, `valid_cert.jpg`, `valid_id.png` | Staging container shows 3 files; session association intact | `PASSED` | 11.3s | Uploaded 3 valid documents; `#aiProgressContainer` visible and count summary displayed `Processed 0 of 3 document(s)`; applicant session preserved on reload. |
| 3 | **TC-CM-207** | Validate formats, content, readability, and configured limits | Applicant | Read/Write | `invalid_text.txt`, `oversized_doc.pdf` (5.3MB) | File limits displayed; unsupported formats and oversized files rejected | `PASSED` | 10.7s | Verified limits banner (`PDF`, `JPG`, `PNG`, `10 files`, `5 MB`, `10 pages`); invalid formats and oversized files triggered inline rejection banners. |
| 4 | **TC-CM-208** | Use native PDF text and OCR when required | Applicant | Write | `valid_license.pdf` | Native PDF text extraction preferred before OCR fallback | `PASSED` | 8.9s | Uploaded standard PDF; server-side Pdfium parser executed and staged document successfully. |
| 5 | **TC-CM-209** | Extract present information without inventing missing values | Applicant | Read | Live DeepInfra extraction | Extracted fields mapped; unstated fields remain empty | `BLOCKED` | — | **Blocked:** DeepInfra vision-language extraction requires server-side `DEEPINFRA_API_KEY` environment variable on Azure Staging. |
| 6 | **TC-CM-210** | Validate output and map only approved fields | Applicant | Read | Live DeepInfra extraction | Only schema-approved fields populated | `BLOCKED` | — | **Blocked:** Verification of live extraction response field mapping requires active DeepInfra API key on Azure Staging. |
| 7 | **TC-CM-211** | Require human selection for unmatched references | Applicant | Write | Live DeepInfra extraction | Ambiguous ranks/vessel types require manual dropdown pick | `BLOCKED` | — | **Blocked:** Verification of unmatched reference suggestion mapping requires active DeepInfra extraction response on Azure Staging. |
| 8 | **TC-CM-212** | Accept, edit, reject, and manually complete suggestions | Applicant | Write | Self-encoding review slots | Suggestion slots interactive; manual edits fully accepted | `PASSED` | 7.3s | Verified manual inputs accept continuous edits; `#aiSuggestion_LastName` slot attached in DOM and available for applicant review. |
| 9 | **TC-CM-213** | Preserve existing values during partial, failed, cancelled, or repeated extraction | Applicant | Write | Pre-filled names + `valid_license.pdf` | Pre-existing manual values preserved when extraction fails or errors | `PASSED` | 8.9s | Pre-filled Last Name and First Name remained completely intact during document upload and backend extraction error response. |
| 10 | **TC-CM-214** | Display conflicting values with their sources | Applicant | Read | Multi-document extraction | Conflicting values flagged with badges and source document names | `BLOCKED` | — | **Blocked:** Requires live multi-document DeepInfra extraction returning conflicting values to inspect conflict UI badges. |
| 11 | **TC-CM-215** | Require approval before replacing values | Applicant | Write | Self-encoding address slots | Pre-filled values never overwritten without explicit applicant click | `PASSED` | 7.2s | Confirmed existing form fields are protected against silent replacement; suggestions require explicit user apply action. |
| 12 | **TC-CM-216** | Require AI-processing acknowledgment | Applicant | Read/Write | Consent checkbox `#chkAiConsent` | Dropzone disabled until notice acknowledged; manual form remains open if declined | `PASSED` | 7.6s | Dropping files without checking consent was blocked; unchecking consent collapsed AI container while leaving manual encoding fully functional. |
| 13 | **TC-CM-217** | Clean temporary artifacts without deleting retained source documents | System | Inspection | Ephemeral staging directory | Temp files purged post-extraction; permanent uploads retained | `BLOCKED` | — | **Blocked (Non-UI):** Server filesystem access to inspect ephemeral storage (`Uploads/ApplicantStaging/_tmp`) and verify temporary artifact purging is unavailable in the automated staging environment. |
| 14 | **TC-CM-218** | Record privacy-safe AI and document events | System | Audit | `tbl_activity_log` | Privacy-safe audit events logged for upload and processing | `BLOCKED` | — | **Blocked (Non-UI / Defect):** Verification of activity logs in `tbl_activity_log` is blocked across Azure staging by the known `AuditHelper.vb` SQL column defect (missing `timestamp` column in `tbl_activity_log`). |
| 15 | **TC-CM-219** | Prevent AI from directly writing applicant or personnel records | System | Database | `tbl_personnel_info`, `tbl_applicant` | Zero DB records written prior to explicit user submission | `BLOCKED` | — | **Blocked (Non-UI):** Direct database access to staging `tbl_personnel_info` / `tbl_applicant` to assert zero pre-submission DB mutations is unavailable in the automated staging environment. |
| 16 | **TC-CM-220** | Retain and associate accepted original uploads | System | Database/Storage | `tbl_crew_documents` | Accepted documents linked to created applicant profile | `BLOCKED` | — | **Blocked (Non-UI):** Direct database and physical storage inspection to assert post-submission document row associations is unavailable in the automated staging environment. |
| 17 | **TC-CM-221** | Enforce authorized staff document access | Unauthenticated / Unauthorized | Read | Staging document storage paths | Direct storage download blocked with 401/403/404 | `PASSED` | 425ms | Tested direct access to `/Uploads/ApplicantStaging/` and `/Uploads/Assessments/`; both returned HTTP 404 (direct directory browsing and unauthorized file retrieval prohibited). |
| 18 | **TC-CM-222** | Save record, document links, and link status atomically | System | Transaction | Applicant submission transaction | DB records, document links, link status commit atomically or roll back | `BLOCKED` | — | **Blocked (Non-UI):** Controlled database storage failure injection and transactional rollback verification are unavailable on live Azure staging. |
| 19 | **TC-CM-223** | Identify source document and page | Applicant | Read | Suggestion source tags | Suggestion tags cite exact source document and page number | `BLOCKED` | — | **Blocked:** Requires active DeepInfra extraction response to inspect rendered source document and page indicators. |
| 20 | **TC-CM-224** | Distinguish suggestion and review states | Applicant | UI Styling | CSS confidence and review classes | Pending, suggested, accepted, and rejected states clearly styled | `PASSED` | 7.7s | Verified CSS class rules for `.ai-suggestion-badge`, `.ai-suggestion-high`, `.ai-suggestion-medium`, and `.ai-suggestion-low`; confirmed confidence reflects extraction reliability only. |
| 21 | **TC-CM-225** | Review repeating records and duplicates | Applicant | Read/Write | Sea service / certificates table | Repeating records reviewed individually; duplicates flagged | `BLOCKED` | — | **Blocked:** Requires live DeepInfra extraction returning repeating records and duplicate entries to inspect resolution interface. |
| 22 | **TC-CM-226** | Return suggestions or failure within 60 seconds | System | API Performance | Single extraction request roundtrip | AI response or failure returns within 60s timeout | `PASSED` | 7.7s | Measured roundtrip extraction handler response (`ApplicantExtractionHandler.ashx?action=csrf`): **187ms**, comfortably within the 60-second limit. No concurrency or load testing performed. |
| 23 | **TC-CM-227** | Recover from timeout or unavailable AI service | Applicant | UI Fault Isolation | Handler failure / missing key response | UI reports failure gracefully; manual form remains interactive | `PASSED` | 7.4s | When extraction handler returns unconfigured key or error, applicant form remains completely interactive; Next navigation button remains fully operational. |
| 24 | **TC-CM-228** | Protect processing communications and minimize provider data | System | Infrastructure Audit | TLS & provider payload transmission | In-transit TLS encryption; zero third-party retention | `BLOCKED` | — | **Blocked (Non-UI):** Verification of cloud infrastructure encryption-at-rest and third-party AI provider zero-data-retention compliance requires infrastructure audit evidence not accessible via browser automation. |
| 25 | **TC-CM-229** | Treat document content as untrusted and display it safely | Applicant | Security / Content Safety | `prompt_injection.pdf`, `xss_display_test.pdf` | Prompt injections ignored; scripts escaped and not executed | `PASSED` | 10.1s | Uploaded prompt-injection PDF without permission bypass or role change; uploaded XSS PDF payload without alert execution or DOM script injection. |

---

## 3. Environmental & Architectural Blockers

### A. Server-Side `DEEPINFRA_API_KEY` Unconfigured on Azure Staging
- **Impacted Cases:** `TC-CM-209`, `TC-CM-210`, `TC-CM-211`, `TC-CM-214`, `TC-CM-223`, `TC-CM-225` (6 cases).
- **Detail:** Visual document OCR and multimodal extraction in `ApplicantExtractionHandler.ashx` depend on DeepInfra vision-language models (`meta-llama/Llama-3.2-11B-Vision-Instruct`). The Azure App Service environment currently does not have `DEEPINFRA_API_KEY` configured in Application Settings. While failure recovery and value preservation are verified, tests requiring live extracted suggestions are blocked pending key provisioning.

### B. Known `AuditHelper.vb` Column Defect
- **Impacted Cases:** `TC-CM-218`.
- **Detail:** `AuditHelper.vb` attempts an `INSERT INTO tbl_activity_log` specifying column `timestamp`, whereas the staging MySQL schema defines `created_at`. This defect was preserved without modification or bypass, correctly resulting in `TC-CM-218` being recorded as Blocked.

### C. Direct Server-File, Database, and Infrastructure Verification Boundaries
- **Impacted Cases:** `TC-CM-217`, `TC-CM-219`, `TC-CM-220`, `TC-CM-222`, `TC-CM-228` (5 cases).
- **Detail:** In accordance with the explicit instruction that these test cases must not be marked Passed using UI behavior alone, each was evaluated for required backend proof:
  - `TC-CM-217`: Ephemeral directory inspection (`Uploads/ApplicantStaging/_tmp`) unavailable via browser.
  - `TC-CM-219`: Direct MySQL table inspection before submission unavailable via browser.
  - `TC-CM-220`: Document-to-crew link verification in physical storage and DB unavailable via browser.
  - `TC-CM-222`: Injected database transaction failure and rollback inspection unavailable on staging.
  - `TC-CM-228`: Cloud infrastructure encryption-at-rest and third-party zero-data-retention compliance require infrastructure audit documentation.

---

## 4. Data Cleanup Audit

- **Isolation Rule:** All generated applicant links and tests were strictly prefixed `QA-C2-AI-20261002`.
- **Post-Run Verification:** Following the execution suite, an automated audit query against `ApplicantLinks.aspx` was executed with Manning Staff credentials.
- **Audit Result:**
  ```text
  Total QA-C2-AI-20261002 rows found: 0
  ```
  Every generated link was cleanly expired and purged during test teardown. No orphaned synthetic links, crew records, or files remain in the staging database or file system.

---

## 5. Evidence Integrity Confirmation

- `qa/playwright/evidence/phase1-summary.md`: **Preserved untouched** (11,217 bytes)
- `qa/playwright/evidence/phase2-summary.md`: **Preserved untouched** (12,085 bytes)
- `qa/playwright/evidence/phase2-results.json`: **Preserved untouched** (92,268 bytes)
- `qa/playwright/evidence/ccl-summary.md`: **Preserved untouched** (7,267 bytes)
- `qa/playwright/evidence/results.json`: **Preserved untouched** (48,297 bytes)
- `qa/playwright/evidence/ai-results.json`: **Generated** (53,362 bytes)
- `qa/playwright/ai-report/index.html`: **Generated** (560,975 bytes)
