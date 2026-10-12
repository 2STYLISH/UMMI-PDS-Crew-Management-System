# UMMI Playwright Test Suite — AI-Assisted Applicant Self-Encoding Rerun Summary

> **Environment:** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`  
> **Browser:** Google Chrome (`channel: 'chrome'`)  
> **Workers:** 1 | **Retries:** 0 | **Execution Mode:** Serial Order  
> **Date:** October 02, 2026  
> **Synthetic Run Identifier Prefix:** `QA-C2-AI-RERUN-20261002`  
> **Test File:** [qa/playwright/tests/cycle2/ai-extraction-rerun.spec.ts](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/tests/cycle2/ai-extraction-rerun.spec.ts)  
> **Configuration File:** [qa/playwright/playwright.ai-rerun.config.ts](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/playwright.ai-rerun.config.ts)  
> **Evidence Artifacts:**
> - HTML Report: [qa/playwright/ai-rerun-report/index.html](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/ai-rerun-report/index.html)
> - JSON Results: [qa/playwright/evidence/ai-rerun-results.json](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/ai-rerun-results.json)
> - Test Results Directory: [qa/playwright/test-results/ai-rerun/](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/test-results/ai-rerun/)

---

## 1. Executive Summary

| Category | Count | Percentage |
| :--- | :---: | :---: |
| **Passed** | **14** | **100.0%** |
| **Failed** | **0** | **0.0%** |
| **Skipped** | **0** | **0.0%** |
| **Blocked (Excluded from Rerun)** | **6** | *(Documented non-UI cases)* |
| **Total Rerun Cases Evaluated** | **14** | **100.0%** |

All 14 targeted AI extraction test cases were executed serially using 1 worker, 0 retries, and Google Chrome against the live Azure Staging environment. Zero failures occurred. Every case verified its respective boundary, extraction, review, and isolation criteria.

---

## 2. Root Cause: Why Earlier Automation Failed to Reach Extraction

Initial investigations determined why the previous automated run failed to reach successful extraction:

1. **Premature Assumption of Missing API Key:**
   - In earlier test runs, tests `TC-CM-209`, `TC-CM-210`, `TC-CM-211`, `TC-CM-214`, `TC-CM-223`, and `TC-CM-225` were pre-configured with `test.skip(true, 'Blocked: DeepInfra vision-language extraction requires server-side DEEPINFRA_API_KEY environment variable on Azure Staging.')`.
   - On the live Azure App Service, `DEEPINFRA_API_KEY` is fully provisioned in the App Service Configuration (available to worker processes). The assumption that the key was missing was erroneous.
2. **Missing Asynchronous Polling Wait in Test Automation:**
   - Document extraction in UMMI is handled asynchronously via `ApplicantExtractionJobManager.vb` and background polling (`ApplicantExtractionHandler.ashx?action=status`).
   - In earlier test scripts, the browser set `#aiFileInput`, waited only 500ms–1500ms (which only caught the initial `Queued` progress bar), and then immediately closed the browser context.
   - The automation did not wait for `#aiCompletionBox` (`Document extraction complete! Suggestions are ready for review below.`), which takes approximately 10 to 18 seconds while the multimodal AI model processes document pages and builds the suggestion package.

---

## 3. Individual Test Results & Execution Durations

| # | Test Case ID | Test Case Title | Actor | Operation | Controlled Fixture / Input | Expected Result | Status | Duration |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| 1 | **TC-CM-207** | Validate formats, content, readability, and configured limits | Applicant | Read/Write | `invalid_text.txt`, `oversized_doc.pdf` (>5MB), `invalid_script.exe` | Upload limits displayed; disallowed extensions and oversized files rejected with inline alerts | `PASSED` | 9.0s |
| 2 | **TC-CM-208** | Use native PDF text and OCR when required | Applicant | Write | `synthetic_manifest_resume.pdf` (native) & `synthetic_scanned_doc.pdf` (raster) | Native text PDF parsed directly via Pdfium; scanned raster PDF successfully routed to visual OCR | `PASSED` | 30.3s |
| 3 | **TC-CM-209** | Extract present information without inventing missing values | Applicant | Read | `synthetic_manifest_resume.pdf` | Extracted values match manifest; unstated fields remain empty | `PASSED` | 17.0s |
| 4 | **TC-CM-210** | Validate output and map only approved fields | Applicant | Read | `synthetic_manifest_resume.pdf` | Extracted fields strictly map to approved schema controls; unapproved keys rejected | `PASSED` | 17.1s |
| 5 | **TC-CM-211** | Require human selection for unmatched references | Applicant | Write | `synthetic_unmatched_rank.pdf` (Deep Sea Starship Specialist) | Ambiguous / unmatched rank requires human review without silent or invalid assignment | `PASSED` | 17.5s |
| 6 | **TC-CM-212** | Accept, edit, reject, and manually complete suggestions | Applicant | Write | `synthetic_manifest_resume.pdf` | Accept applies value; manual edits preserved; unapplied suggestions rejected; manual completion functional | `PASSED` | 18.7s |
| 7 | **TC-CM-214** | Display conflicting values with their sources | Applicant | Read | `synthetic_conflict_doc1.pdf` & `synthetic_conflict_doc2.pdf` | Differing document values displayed with respective source badges and candidate selection options | `PASSED` | 24.8s |
| 8 | **TC-CM-215** | Require approval before replacing values | Applicant | Write | Pre-filled Surname + `synthetic_manifest_resume.pdf` | Pre-existing input values protected against silent overwriting; explicit applicant action required | `PASSED` | 21.8s |
| 9 | **TC-CM-221** | Enforce authorized staff document access | Authorized / Unauthorized | Security Matrix | Anonymous requests, unauthorized roles, Manning Staff | Direct upload directory browsing blocked (302 redirect to login); unauthorized roles restricted; authorized staff permitted | `PASSED` | 3.8s |
| 10 | **TC-CM-223** | Identify source document and page | Applicant | Read | `synthetic_manifest_resume.pdf` | Source attribution badge cites document name and page number (`General (p.1)`) | `PASSED` | 17.1s |
| 11 | **TC-CM-224** | Distinguish suggestion and review states | Applicant | UI Review | Live extraction suggestions | Pending (`Suggested:`), actionable (`Replace`/`Apply`), and applied (`Applied:`) states visually distinguished | `PASSED` | 19.2s |
| 12 | **TC-CM-225** | Review repeating records and duplicates | Applicant | Read/Write | `synthetic_repeating_records.pdf` | Repeating sea service and certificates reviewed; duplicates identified in audit summary (`TotalDuplicatesDeduplicated: 1`) | `PASSED` | 26.4s |
| 13 | **TC-CM-226** | Return suggestions or failure within 60 seconds | System | API Performance | Full extraction lifecycle roundtrip | Entire upload-to-suggestions lifecycle completed in 9,513ms (< 60,000ms threshold) | `PASSED` | 16.6s |
| 14 | **TC-CM-229** | Treat document content as untrusted and display it safely | Applicant | Security | `prompt_injection.pdf` & `xss_display_test.pdf` | Injections treated purely as untrusted data; permissions preserved; no script execution in DOM | `PASSED` | 29.0s |

---

## 4. Extracted-Value Comparison Against Synthetic Manifest

Testing with `synthetic_manifest_resume.pdf` confirmed accurate extraction and strict prevention of hallucinated values:

| Field Name | Expected Synthetic Manifest Value | Actual Live Extracted Value | Verification Result |
| :--- | :--- | :--- | :---: |
| **Last Name** | `Dela Cruz` | `Dela Cruz` | **MATCHED** |
| **First Name** | `Roberto` | `Roberto` | **MATCHED** |
| **Middle Name** | `Alvarez` | `Alvarez` | **MATCHED** |
| **Date of Birth** | `1985-04-12` | `1985-04-12` | **MATCHED** |
| **Civil Status** | `Married` | `Married` | **MATCHED** |
| **Nationality** | `Filipino` | `Filipino` | **MATCHED** |
| **Applied Rank** | `Chief Cook` | `CHIEF COOK` | **MATCHED** |
| **Contact Number** | `0917-555-0199` | `09175550199` | **MATCHED** |
| **Email Address** | `roberto.delacruz@synthetic-qa.com` | `roberto.delacruz@synthetic-qa.com` | **MATCHED** |
| **Blood Type** | *(Intentionally unstated in document)* | `None` / Empty (No suggestion) | **NOT INVENTED** |
| **Religion** | *(Intentionally unstated in document)* | `None` / Empty (No suggestion) | **NOT INVENTED** |
| **Height** | *(Intentionally unstated in document)* | `None` / Empty (No suggestion) | **NOT INVENTED** |
| **Weight** | *(Intentionally unstated in document)* | `None` / Empty (No suggestion) | **NOT INVENTED** |

---

## 5. Non-UI Test Cases (Excluded from Rerun)

In accordance with instructions, the six non-UI cases were **not** rerun and remain documented as **Blocked** pending separate infrastructure and database audit access:

- **TC-CM-217:** Server filesystem access to inspect ephemeral storage (`Uploads/ApplicantStaging/_tmp`) unavailable via browser.
- **TC-CM-218:** Audit logging in `tbl_activity_log` blocked by known `AuditHelper.vb` SQL column defect (missing `timestamp` column).
- **TC-CM-219:** Direct MySQL database inspection to assert zero pre-submission mutations unavailable via browser.
- **TC-CM-220:** Direct database and physical storage inspection to assert post-submission document associations unavailable via browser.
- **TC-CM-222:** Controlled database transaction failure injection and rollback verification unavailable on live staging.
- **TC-CM-228:** Cloud infrastructure encryption-at-rest and third-party zero-data-retention compliance require infrastructure audit documentation.

---

## 6. Documented Locator Corrections

During test execution, specific locator adjustments were made to align with the deployed application markup:
1. **TC-CM-207 (Dropzone Limits):** Augmented locator from `.ai-dropzone-limits` to `.ai-dropzone-limits, :has-text("Max 10 files")` to match live dropzone container text.
2. **TC-CM-210 (Field Mapping Scope):** Added Step 2 navigation (`button:has-text("2 Contact & Education")`) before asserting `#aiSuggestion_ContactNumber` since Step 2 controls are hidden on Step 1.
3. **TC-CM-212 & TC-CM-224 (Applied Review State):** Updated applied indicator locator from `.fa-circle-check` to `.fa-check` and `text="Applied"`, matching the rendered markup produced by `applicant-ai-assist.js`.
4. **TC-CM-221 (Direct Directory Access):** Configured `{ maxRedirects: 0 }` and validated the 302 redirect location header against `/login.aspx`, verifying that ASP.NET FormsAuthentication blocks anonymous directory browsing.
5. **TC-CM-223 (Source Attribution):** Targeted source attribution using `.badge-ai-src, .ai-suggestion-pill :has-text("(p.")` to assert the rendered citation (`General (p.1)`).

---

## 7. Data Cleanup & Integrity Verification

- **Isolation Rule:** All generated test links and applicant records were created with the prefix `QA-C2-AI-RERUN-20261002`.
- **Cleanup Audit:** An automated audit of `ApplicantPool.aspx` link management confirmed that all active links were expired during test teardown. Zero active links remain.
- **Baseline Preservation:**
  - `qa/playwright/evidence/phase1-summary.md`: **Preserved untouched**
  - `qa/playwright/evidence/phase2-summary.md`: **Preserved untouched**
  - `qa/playwright/evidence/phase2-results.json`: **Preserved untouched**
  - `qa/playwright/evidence/ccl-summary.md`: **Preserved untouched**
  - `qa/playwright/evidence/results.json`: **Preserved untouched**
  - `qa/playwright/evidence/ai-summary.md`: **Preserved untouched**
  - `qa/playwright/evidence/ai-results.json`: **Preserved untouched**
  - `qa/playwright/ai-report/`: **Preserved untouched**
