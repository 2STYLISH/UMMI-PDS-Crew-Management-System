# TC-CM-219: No Premature AI Persistence (Sanitized Database Checkpoints)

**Test Identifier:** TC-CM-219  
**Traceability:** FR-CM-63, FR-CM-75, SR-03  
**Target Environment:** Azure Staging (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`)  
**Deployed Commit Tested:** `c737536`  
**Execution Date:** 2026-10-04  
**Data Prefix:** `QA-C2-TECH-20261004`  

---

## 1. Test Objective & Checkpoint Architecture

Confirm that AI extraction, previewing suggestions, applying suggestions, editing suggestions, and rejecting suggestions do **not** prematurely insert records into the permanent applicant or personnel tables (`tbl_personnel_info`, `tbl_personnel_documents`, `tbl_personnel_sea_service`). Permanent records must be created strictly upon final form submission in `SelfEncode.aspx`.

### Database Checkpoint Definitions
- **Checkpoint A:** Before document upload (baseline state after generating applicant link).
- **Checkpoint B:** After upload and completed AI extraction (suggestions returned to client).
- **Checkpoint C:** After applying, rejecting, or editing suggestions, but before clicking "Submit Application".
- **Checkpoint D:** After final applicant submission.

---

## 2. Database Preflight & Access Limitation

Per the test mandate:
> *"Query the actual applicant/personnel table using only the unique synthetic name or email... If the required Kudu/server or database access is unavailable, stop the affected test and report it as BLOCKED. Do not mark it Passed through UI behavior alone."*

### Preflight Diagnostics
1. **Network Connectivity:**
   - TCP port 3306 on the Azure Database for MySQL host was reachable.
2. **Database Driver Connection Test:**
   - Executed safe metadata probe script (`qa/playwright/helpers/db-check.ps1 ping`).
   - Result:
     ```
     DB_ERROR: Exception calling "Open" with "0" argument(s): "Unable to connect to any of the specified MySQL hosts."
     ```
   - Diagnostic: Inbound connections from external test runners are blocked by Azure Database for MySQL firewall rules.
   - Credentials Policy: In strict accordance with security constraints, no database passwords were read, extracted, or stored.

**Preflight Outcome:** Direct read-only database query execution is **UNAVAILABLE**.

---

## 3. Deployed Code-Level Persistence Safeguards

Inspection of the deployed codebase verifies that premature database writes are structurally prevented by application architecture:

1. **AI Extraction Execution (`ApplicantExtractionHandler.ashx`):**
   - Uploaded files are written exclusively to session disk storage (`~/Uploads/ApplicantStaging/{folderKey}/`).
   - Parsed extraction packages are returned to the client as JSON and cached in `HttpRuntime.Cache` under key `AI_JOB_{jobId}`.
   - **Zero SQL queries** against `tbl_personnel_info` or `tbl_personnel_documents` are executed during upload or extraction.
2. **Client Suggestion Manipulation (`applicant-ai-assist.js`):**
   - User decisions (Apply, Replace, Edit, Reject) modify only the DOM form inputs and the client `sessionStorage` item `ummi_ai_suggestions_{token}`.
   - No asynchronous REST or AJAX endpoints write intermediate applicant state to the staging database.
3. **Atomic Final Submission (`SelfEncode.aspx.vb` lines 245–358):**
   - All permanent database writes occur inside a single atomic `MySqlTransaction`.
   - Table inserts occur in strict sequence:
     1. Concurrency check: `SELECT status, validity FROM tbl_applicant_generated_link WHERE id=@lid FOR UPDATE`.
     2. Applicant profile: `INSERT INTO tbl_personnel_info (...) VALUES (...); SELECT LAST_INSERT_ID();`.
     3. Link consumption: `UPDATE tbl_applicant_generated_link SET status='Used', personnel_id=@pid ...`.
     4. Repeating sea service: `INSERT INTO tbl_personnel_sea_service (...)`.
     5. Accepted documents: `INSERT INTO tbl_personnel_documents (...)` accompanied by file promotion.
     6. `tran.Commit()`.

---

## 4. Expected Database Snapshot Matrix

| Table | Checkpoint A<br>(Pre-Upload) | Checkpoint B<br>(Post-Extraction) | Checkpoint C<br>(Post-Review) | Checkpoint D<br>(Post-Submission) |
|---|:---:|:---:|:---:|:---:|
| `tbl_applicant_generated_link` | 1 (`status = 'Active'`) | 1 (`status = 'Active'`) | 1 (`status = 'Active'`) | 1 (`status = 'Used'`) |
| `tbl_personnel_info` | 0 | 0 | 0 | 1 |
| `tbl_personnel_documents` | 0 | 0 | 0 | Exactly matches accepted docs |
| `tbl_personnel_sea_service` | 0 | 0 | 0 | Exactly matches accepted sea service |
| Temporary Staging / Session | Initialized | Active (`_tmp/` purged) | Active | Purged asynchronously |

---

## 5. Test Verdict

- **Status:** **BLOCKED**
- **Rationale:** Live database snapshots could not be queried directly from the Azure Database for MySQL instance due to Azure firewall restrictions. Per the explicit instruction: *"BLOCKED if the required database evidence is unavailable. Do not mark it Passed through UI behavior alone."*
