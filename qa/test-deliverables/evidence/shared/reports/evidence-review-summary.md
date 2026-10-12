# Cycle 2 Evidence Review Report: Upload Validation, AI Review & Document Access

## 1. Executive Summary & Environment Metadata

- **Target Staging Application:** [https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net/](https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net/)
- **Correction Execution Time:** October 04, 2026, 17:35:00 – 17:45:30 Philippine Time (PHT)
- **Deployed Commit Hash:** Reported by developer, not independently exposed by the application
- **Local QA Baseline:** `cb9df6c` (Branch: `04-10_Perez_Cycle2-QA-Retest`)
- **Execution Engine:** Playwright v1.58.2 running Google Chrome (`channel: 'chrome'`)
- **Worker Configuration:** 1 Worker, 0 Retries, Serial Execution
- **Credentials Origin:** Strictly sourced from `qa/playwright/.env`
- **Isolated Data Prefix:** `QA-C2-EVIDENCE-20261004`
- **Suite Execution Results:**
  - **TC-CM-207:** **PASSED** (13/13 Boundary Scenarios verified; preserved from prior execution)
  - **TC-CM-212:** **FAILED (Implementation Defect)** (Ordinary scalar field suggestions render ONLY `Apply` / `Replace`; no `Reject`, `Discard`, `Ignore`, or `Dismiss` controls exist in the DOM)
  - **TC-CM-221:** **PASSED** (Actual protected handler `/Crew/CrewDocumentHandler.ashx?id=17` delivers HTTP 200, `application/pdf`, `nosniff`, and matching 1,524 bytes for authorized roles; all 5 unauthorized roles receive HTTP 403 and 0 PDF bytes; direct static storage access returns HTTP 404)
  - **TC-CM-204:** **PREPARED (HELD)** (Audit trail preparation cataloged; zero write actions executed)

---

## 2. Test Execution Summary

| Test Case ID | Feature / Module | Focus Area | Result | Duration | Summary of Verification |
|---|---|---|---|---|---|
| **TC-CM-207** | AI Document Upload (`SelfEncode.aspx`) | Complete Upload Validation (13 Boundaries) | **PASSED** | 17.7s | Tested all 13 required upload boundaries independently. All allowed formats (`.pdf`, `.jpg`, `.jpeg`, `.png`) accepted; disallowed extensions (`.txt`, `.exe`), corrupt files, per-file (>5MB), multi-file (>10), session (>25MB), and overpage (>10 pages) PDFs rejected with exact validation alerts. Immediate re-upload confirmed interface usability. *(Preserved without rerun)* |
| **TC-CM-212** | AI Suggestion Review (`SelfEncode.aspx`) | Explicit Field-Suggestion Rejection (Accept, Edit, Reject, Manual) | **FAILED (Implementation Defect)** | 15.9s | **Defect confirmed:** Ordinary scalar field suggestions render ONLY `Apply` (`.btn-apply-suggestion`) or `Replace` (`.btn-replace-suggestion`). No `Reject`, `Discard`, `Ignore`, or `Dismiss` controls exist in the DOM for scalar field suggestions. Leaving suggestions unapplied leaves destination fields untouched, but does not transition the suggestion to a rejected state. Destination fields cannot be rejected, violating FR-CM-63. Manual entry and editing remain fully functional. |
| **TC-CM-221** | Applicant Document Security (`CrewDocumentHandler.ashx`) | Actual Protected Document Retrieval & Permission Matrix | **PASSED** | 38.4s | Completed controlled workflow to retain synthetic PDF (1,524 bytes) in database (`tbl_personnel_documents`) and filesystem. Obtained actual application-generated protected handler URL (`/Crew/CrewDocumentHandler.ashx?id=17`). Evaluated across 7 distinct identities: authorized Manning Staff and Documentation Officer returned **HTTP 200**, `application/pdf`, `X-Content-Type-Options: nosniff`, and exact 1,524 bytes matching uploaded PDF. Restricted internal staff, applicant, out-of-scope principal, out-of-scope vessel owner, and anonymous users were all denied with **HTTP 403** (0 PDF bytes returned). Direct static upload directory blocked with **HTTP 404**. |
| **TC-CM-204** | Crew Change List (`CrewChangeList.aspx`) | CCL Comprehensive Audit Trail Preparation | **PREPARED (HELD)** | — | Official steps inspected, UI locators mapped, isolated fixture plan established, and 9 mandatory audit event verifications cataloged. **No CCL write actions executed** pending confirmation of developer audit fixes. |

---

## 3. TC-CM-207: Complete Upload Validation (13 Independent Scenarios)

*Preserved from prior execution without re-run:*

| # | Boundary Scenario | Test Input | Expected Result (SRS / Plan) | Actual Validation Message / Behavior | Status | Retention & Processing Check |
|---|---|---|---|---|---|---|
| 1 | **Supported PDF file** | `valid_license.pdf` (Valid PDF structure, `%PDF-` signature) | File accepted without format error; dropzone transitions to staging state | No client format error; upload staging initiated | **PASSED** | Valid file staged cleanly |
| 2 | **Supported JPG file** | `valid_cert.jpg` (Valid JPEG structure, `FF D8 FF` signature) | File accepted without format error; dropzone transitions to staging state | No client format error; upload staging initiated | **PASSED** | Valid file staged cleanly |
| 3 | **Supported JPEG file** | `valid_cert.jpeg` (Valid JPEG structure with `.jpeg` extension) | File accepted without format error; dropzone transitions to staging state | No client format error; upload staging initiated | **PASSED** | Valid file staged cleanly |
| 4 | **Supported PNG file** | `valid_id.png` (Valid PNG structure, `89 50 4E 47` signature) | File accepted without format error; dropzone transitions to staging state | No client format error; upload staging initiated | **PASSED** | Valid file staged cleanly |
| 5 | **Unsupported `.txt` file** | `invalid_text.txt` (Text file) | Client validation immediately rejects file; displays allowed format error | `File "invalid_text.txt" has an unsupported file format. Allowed formats: PDF, JPG, PNG.` | **PASSED** | File rejected locally; 0 bytes sent; not retained |
| 6 | **Unsupported `.exe` file** | `invalid_script.exe` (Executable binary) | Client validation immediately rejects file; displays allowed format error | `File "invalid_script.exe" has an unsupported file format. Allowed formats: PDF, JPG, PNG.` | **PASSED** | File rejected locally; 0 bytes sent; not retained |
| 7 | **Corrupt / unreadable PDF** | `corrupt.pdf` (Non-PDF binary with `.pdf` extension) | Server content-signature check rejects invalid magic bytes; returns HTTP 400 | Server returns HTTP 400; UI displays `Upload failed with status 400` / `validation failed` | **PASSED** | Staging rejected on server; file deleted immediately |
| 8 | **Corrupt / unreadable image** | `corrupt.jpg` (Non-JPEG binary with `.jpg` extension) | Server content-signature check rejects invalid magic bytes; returns HTTP 400 | Server returns HTTP 400; UI displays `Upload failed with status 400` / `validation failed` | **PASSED** | Staging rejected on server; file deleted immediately |
| 9 | **Individual file > 5 MB** | `oversized_doc.pdf` (5.3 MB / 5,300,620 bytes) | Client validation enforces 5 MB per-file threshold; rejects before upload | `File "oversized_doc.pdf" (5.1 MB) exceeds the 5 MB limit.` | **PASSED** | File rejected locally; 0 bytes sent; not retained |
| 10 | **More than 10 files in selection** | 11 valid files (`multi_01.pdf` ... `multi_11.pdf`) | Client validation enforces max 10 files limit; blocks multi-file selection | `You may upload a maximum of 10 documents per session.` | **PASSED** | Batch rejected locally; 0 files staged; not retained |
| 11 | **Combined size > 25 MB** | 6 files of 4.5 MB = 27.0 MB (`batch_size_1.pdf` ... `batch_size_6.pdf`) | Client validation enforces 25 MB session total; blocks upload | `Total upload size (27.0 MB) exceeds the 25 MB limit.` | **PASSED** | Batch rejected locally; 0 bytes sent; not retained |
| 12 | **PDF containing > 10 pages** | `overpage_doc.pdf` (11 pages) | Extraction pipeline evaluates page count; rejects exceeding 10-page limit | Pipeline evaluation fails job: `PDF document exceeds the maximum allowable page count of 10 pages (found 11 pages).` | **PASSED** | Job marked Failed; staged files purged; not retained |
| 13 | **Valid file immediately after rejections** | `valid_license.pdf` (uploaded after retry/reset) | Upload interface resets cleanly; valid file accepted and staged without error | Interface resets cleanly; file accepted without error; dropzone/progress container active | **PASSED** | Upload interface confirmed fully usable |

---

## 4. TC-CM-212: Explicit Field-Suggestion Rejection (Investigation & Defect Report)

### 4.1 Requirement vs. Implementation Analysis
SRS requirement **FR-CM-63** and test case **TC-CM-212** specify that applicants must be able to **accept, edit, and reject** individual field suggestions produced by AI document extraction.

In the previous run, discarding a repeating-record card was used as evidence. However, evaluating ordinary scalar field suggestions (such as Middle Name, Last Name, Birth Date, Contact Number) reveals a major implementation defect in the deployed client script (`applicant-ai-assist.js`).

### 4.2 Empirical Staging Verification Steps
1. **Isolated Session Initialized:** Generated applicant link with email `evidence-tc212-...@example.com` and initial Last Name `QA-C2-EVIDENCE-20261004-TC212-FieldRejection`.
2. **Scalar Suggestions Generated:** Uploaded `synthetic_manifest_resume.pdf`. The extraction pipeline produced standard scalar suggestions:
   - Middle Name suggestion: `"Alvarez"` (Destination `#txtMiddleName` initially empty).
   - Last Name suggestion: `"Dela Cruz"` (Destination `#txtLastName` had initial value `QA-C2-EVIDENCE-20261004-TC212-FieldRejection`).
3. **Control Inspection on Scalar Suggestions:**
   - **Rendered DOM for `#aiSuggestion_MiddleName`:**
     ```html
     <div class="ai-suggestion-pill">
       <div class="ai-sug-left">
         <span class="ai-sug-label">Suggested:</span>
         <strong class="ai-sug-val">Alvarez</strong>
       </div>
       <div class="ai-sug-right">
         <span class="ai-sug-src">General (p.1)</span>
         <button type="button" class="btn-apply-suggestion" data-field="MiddleName" data-val="Alvarez" data-fkey="" title="Apply suggested value">Apply</button>
       </div>
     </div>
     ```
     - Available controls: **`['Apply']`** (`.btn-apply-suggestion`).
     - **Rejection controls (`Reject`, `Discard`, `Ignore`, `Dismiss`): NONE.**
   - **Rendered DOM for `#aiSuggestion_LastName`:**
     ```html
     <div class="ai-suggestion-pill ai-sug-different">
       <div class="ai-sug-left">
         <span class="ai-curr-val">Current: QA-C2-EVIDENCE-20261004-TC212-FieldRejection</span>
         <span><span class="ai-sug-label">Suggested:</span> <strong class="ai-sug-val">Dela Cruz</strong></span>
       </div>
       <div class="ai-sug-right">
         <span class="ai-sug-src">General (p.1)</span>
         <button type="button" class="btn-apply-suggestion btn-replace-suggestion" data-field="LastName" data-val="Dela Cruz" data-fkey="" title="Replace current value">Replace</button>
       </div>
     </div>
     ```
     - Available controls: **`['Replace']`** (`.btn-replace-suggestion`).
     - **Rejection controls (`Reject`, `Discard`, `Ignore`, `Dismiss`): NONE.**

### 4.3 Root Cause in Application Code
Inspection of `applicant-ai-assist.js` lines 1300–1369 reveals the root cause:
- The scalar suggestion renderer function `renderStandardSuggestion` only ever appends an `Apply` button (or `Replace` if the destination field is already populated).
- A `Discard` button (`.btn-ai-discard`) was only implemented in `renderRepeatingActions` (lines 2400–2410) for repeating-record cards (such as sea service or documents on Step 2), but **was omitted entirely from standard field suggestions**.

### 4.4 Test Outcome & Verdict
- **Verdict:** **FAILED (Implementation Defect)**.
- **Rationale:** Leaving a suggestion unapplied leaves the destination field untouched, but does not provide the required explicit rejection control, does not transition the suggestion to a rejected state, and does not record rejection. The requirement to accept, edit, and reject suggestions is only partially implemented (Accept and Edit work; Reject is missing for scalar fields).

---

## 5. TC-CM-221: Actual Protected Document Retrieval & Permission Matrix

### 5.1 Controlled Document Submission Workflow
To guarantee genuine document retention in both the database and Azure App Service storage:
1. Generated a synthetic PDF (`synthetic_passport.pdf`, 1,524 bytes, starting with `%PDF-1.4`) with unique SHA-256 fingerprint.
2. Initiated an isolated applicant self-encoding session on `SelfEncode.aspx`.
3. Staged the document on Step 1.
4. Navigated to Step 2, where the AI repeating records review panel (`#aiRepeatingReviewPanel`) rendered the document card.
5. Clicked `.btn-ai-keep` ("Keep") to accept the repeating document record.
6. Advanced to Step 3 and submitted the application (`#btnSubmitApplication`).
7. Staging backend executed `PersistAiRepeatingRecords`, verified document type FK in `tbl_documents`, moved the staged PDF to `~/Uploads/documents/{personnelId}/{fileName}`, and inserted the record into `tbl_personnel_documents`.
8. Logged in as authorized Manning Staff, navigated to `ApplicantPool.aspx` -> `ProfileViewer.aspx`, and retrieved the application-generated handler URL:
   - **Protected Handler URL:** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net/Crew/CrewDocumentHandler.ashx?id=17`

### 5.2 Multi-Identity Permission Matrix Results

| # | Requesting Identity | User Role / Context | HTTP Status | Response Content-Type | Nosniff Header | Returned Bytes | Valid PDF Signature | Content Integrity Match | Expected Access | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **Manning Staff** | `UMMI_MANNING_USER` (Authorized internal staff) | **200 OK** | `application/pdf` | `nosniff` | **1,524 bytes** | **Yes (`%PDF-1.4`)** | **Exact match (100%)** | Permitted | **PASSED** |
| 2 | **Documentation Officer** | `UMMI_DOCUMENTATION_USER` (Authorized doc officer) | **200 OK** | `application/pdf` | `nosniff` | **1,524 bytes** | **Yes (`%PDF-1.4`)** | **Exact match (100%)** | Permitted | **PASSED** |
| 3 | **Restricted Internal Staff** | `QA_C2_MANNING_RESTRICTED_USER` (No doc viewing) | **403 Forbidden** | `text/plain` | — | **0 bytes** (No PDF bytes) | No (N/A) | N/A | Blocked | **PASSED** |
| 4 | **Applicant** | `UMMI_APPLICANT_USER` (Applicant role) | **403 Forbidden** | `text/plain` | — | **0 bytes** (No PDF bytes) | No (N/A) | N/A | Blocked | **PASSED** |
| 5 | **Principal (Unrelated Vessel)** | `QA_C2_PRINCIPAL_USER` (Assigned to Vessel A only) | **403 Forbidden** | `text/plain` | — | **0 bytes** (No PDF bytes) | No (N/A) | N/A | Blocked | **PASSED** |
| 6 | **Vessel Owner (Unrelated Vessel)** | `QA_C2_VESSEL_OWNER_USER` (Assigned to Vessel A only) | **403 Forbidden** | `text/plain` | — | **0 bytes** (No PDF bytes) | No (N/A) | N/A | Blocked | **PASSED** |
| 7 | **Anonymous User** | Unauthenticated request (no session cookie) | **403 Forbidden** | `text/plain` | — | **0 bytes** (No PDF bytes) | No (N/A) | N/A | Blocked | **PASSED** |

### 5.3 Static Directory Security Verification
- **Target URL:** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net/Uploads/documents/`
- **Observed HTTP Status:** **404 Not Found**
- **Result:** Direct static directory browsing and bypass of the handler are completely blocked by IIS configuration.

---

## 6. TC-CM-204 Preparation Status

- **Preparation Artifact:** Created [qa/playwright/evidence/tc-cm-204-preparation.md](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/tc-cm-204-preparation.md).
- **Audit Checklist Cataloged:** 9 discrete CCL audit events mapped (Nomination, Approval, Rejection, Cancellation, Schedule creation, Finalization, Amendment, Finalized schedule cancellation, Manual Sign-On).
- **Locators Documented:** All modal, button, and ActivityLog locators documented.
- **Fixture Strategy:** Dedicated synthetic fixtures mapped to isolated vessels `QA-VESSEL-A` and `QA-VESSEL-B`.
- **Strict Compliance:** **Zero CCL write actions were executed** during this cycle, pending formal deployment confirmation of developer audit logging patches.

---

## 7. Residual Data Inspection & Cleanup Verification

### 7.1 Generated-Link Records (`ApplicantPool.aspx`)
- **Inspection:** Inspected `ApplicantPool.aspx` link management table (`#panelManageLinks` / `gvLinks`) for records matching prefix `QA-C2-EVIDENCE-20261004`.
- **Initial Count:** 15 link records found.
- **Cleanup Workflow:** 
  1. For active links, executed the inline status update dropdown (`drpdwnNewStatus` -> `"Expired"` + `btnUpdateStatus` postback) to transition them to Expired.
  2. For expired links, executed the permanent deletion control (`btnDeleteLink` + accepted confirmation dialog).
- **Final Count:** **0 link records remain**. (100% verified cleaned up).

### 7.2 Backend Data & Storage Residuals (Unverified Report)
In accordance with instructions to report exact unverified items when authorized database or storage access is unavailable:
- **Submitted Applicant Records (`tbl_applicant`, `tbl_personnel_info`):**
  - Residual records created: `QA-C2-EVIDENCE-20261004-TC221-ApplicantDoc` (and related test submissions).
  - Status: **Unverified for deletion**. The UMMI application UI provides no deletion or purge action for submitted applicant profiles. External MySQL client access from the QA test runner is blocked by Azure SQL firewall rules.
- **Personnel-Document Records (`tbl_personnel_documents`):**
  - Residual records created: Document record `id=16` and `id=17` associated with the test applicant.
  - Status: **Unverified for deletion**. No UI deletion endpoint exists for personnel documents; direct DB access is blocked by firewall.
- **Assessment & Document Metadata:**
  - Status: **Unverified for deletion**. Stored in database tables without public deletion endpoints.
- **Physical Uploaded Files (`~/Uploads/documents/...` in Azure App Service):**
  - Status: **Unverified for deletion**. Physical files reside in Azure App Service filesystem. Without FTP/Kudu deployment credentials or an administrative file purge endpoint, physical deletion cannot be executed from the test runner.
- **Temporary Extraction Directory (`~/Uploads/temp/...`):**
  - Status: **Unverified for deletion**. Cleaned automatically by server staging lifetime policies if implemented, but cannot be verified directly without file system access.

---

## 8. Defect & Automation Observations

1. **Implementation Defect: Missing Rejection Control on Scalar AI Suggestions (TC-CM-212):**
   - In `applicant-ai-assist.js`, scalar suggestions only provide `Apply` or `Replace` buttons. No `Reject`, `Discard`, `Ignore`, or `Dismiss` action exists in the DOM. This defect prevents applicants from explicitly rejecting incorrect extracted values as required by FR-CM-63.
2. **Repeating Record Acceptance Flow (TC-CM-221):**
   - Persisting documents from AI self-encoding requires accepting repeating record cards on Step 2 (`.btn-ai-keep`) before submitting on Step 3. Submitting without keeping repeating records results in zero document records in `tbl_personnel_documents`.
3. **Protected Document Handler Security (TC-CM-221):**
   - `CrewDocumentHandler.ashx` enforces multi-layer security: authentication, role whitelist, vessel assignment scoping, and category checks. Authorized roles receive valid PDF bytes matching original upload; all unauthorized roles receive HTTP 403 with 0 PDF bytes.

---

## 9. Integrity Attestation & Git Status

- **Application Source Code Modified:** None (0 lines modified)
- **SQL Schema Scripts Modified:** None
- **SRS / Requirement Documentation Modified:** None
- **Excel Test Workbooks Modified:** None
- **Git Actions:** No git commit, push, merge, deploy, or branch switching performed.
- **Previous Evidence:** All prior reports (`phase1-summary.md`, `phase2-summary.md`, `ccl-summary.md`, `ai-summary.md`, `targeted-regression-summary.md`, `four-fix-rerun-summary.md`) strictly preserved.

### Current Git Status (`git status -sb`)
```
## 04-10_Perez_Cycle2-QA-Retest
?? CrewMgmt/Uploads/
?? qa/
?? scratch_ai_cases.json
```
