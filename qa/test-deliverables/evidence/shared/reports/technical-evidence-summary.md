# UMMI Cycle 2 — Controlled Technical Evidence Summary

**Execution Date:** 2026-10-04  
**Target Environment:** Azure Staging (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`)  
**Deployed Commit Tested:** `c737536` (*Fix: Blank outgoing crew name in schedule popups and mobile responsive view*)  
**Execution Profile:** Google Chrome (Headless), 1 Worker, 0 Retries, Serial Execution  
**Data Prefix:** `QA-C2-TECH-20261004` (Isolated Synthetic Data)  

---

## 1. Executive Summary

This report documents the controlled technical-evidence run for **TC-CM-217**, **TC-CM-219**, **TC-CM-220**, and **TC-CM-186** against the live deployed Azure Staging application.

Per the testing mandate:
- Direct inspection requires already-authorized Azure Kudu/SSH and read-only Azure Database for MySQL connectivity.
- Bypassing the Azure firewall is strictly prohibited.
- If required Kudu/server or database access is unavailable, affected tests must be stopped and reported as **BLOCKED**; they cannot be marked Passed through UI behavior alone.
- For TC-CM-186, if database inspection cannot be completed, the status must remain **PASSED WITH TECHNICAL LIMITATION**.

### Test Execution Matrix

| Test Case | Scope / Requirement | Verification Mode | Status | Technical Finding / Limitation |
|---|---|---|:---:|---|
| **Access Preflight** | Connectivity, commit tracking, Kudu/SSH & MySQL smoke test | HTTP Probe / Network Probe / Codebase Analysis | **Completed (Limitations Recorded)** | Staging reachable (HTTP 302/200); deployed commit verified as `c737536`; Kudu/SSH SCM endpoint unavailable (`ENOTFOUND`); MySQL port 3306 reachable but inbound connections blocked by Azure MySQL firewall. |
| **TC-CM-217** | Temporary AI artifact cleanup (FR-CM-69, FR-CM-73) | Kudu/SSH Filesystem Snapshot | **BLOCKED** | Direct Kudu/SSH server filesystem inspection is unavailable (`ENOTFOUND` on SCM domain). Cannot collect sanitized server disk inventories via UI alone per mandate. |
| **TC-CM-219** | No premature AI persistence (FR-CM-63, FR-CM-75) | MySQL Snapshots at Checkpoints A, B, C, D | **BLOCKED** | Direct read-only Azure MySQL queries are blocked by Azure database firewall. Checkpoint row counts cannot be verified directly in DB per mandate. |
| **TC-CM-220** | Retained applicant-document association (FR-CM-65, FR-CM-68) | DB FK link, physical file hash, protected handler matrix | **BLOCKED** | Database and server filesystem inspection unavailable. Furthermore, deployed protected handler `/Crew/CrewDocumentHandler.ashx` returns HTTP 404 on Azure staging; static path `/Uploads/documents/` is verified blocked (HTTP 404). |
| **TC-CM-186** | Secure credential storage (SR-04) | Codebase + DB Aggregate Schema | **PASSED WITH TECHNICAL LIMITATION** | Application codebase (`CryptoHelper.vb`) conclusively satisfies SR-04 using PBKDF2-HMAC-SHA256 with 100,000 iterations and 256-bit cryptographically random salt. Direct DB inspection is blocked by Azure MySQL firewall. |

---

## 2. Access Preflight Results

1. **Target Reachability:**  
   - `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net` returns HTTP 302 (redirecting unauthenticated requests to `/login.aspx?ReturnUrl=%2f`).
   - Server: `Microsoft-IIS/10.0`, ASP.NET Version: `4.0.30319`.
2. **Deployed Commit Recorded:**  
   - Commit: `c7375362b2b5f2461c7b4fcb939064e9e8a8b17d` (`c737536`).
   - Verified via runtime probe of `scripts/applicant-ai-assist.js` on staging.
3. **Kudu/SSH Access Preflight:**  
   - Domain: `ummi-crew-hdccaegqbke9gwab.scm.azurewebsites.net`.
   - Result: `getaddrinfo ENOTFOUND`. The Azure App Service public SCM/Kudu endpoint is disabled or not publicly routed.
   - Status: **UNAVAILABLE / BLOCKED**.
4. **MySQL Access Preflight:**  
   - Probed configured `QA_DB_HOST` on port 3306.
   - Result: TCP connection succeeds, but database connection initialization via `MySql.Data.MySqlClient` fails with:  
     `DB_ERROR: Exception calling "Open" with "0" argument(s): "Unable to connect to any of the specified MySQL hosts."`
   - Cause: Azure Database for MySQL firewall rules restrict inbound client connections, and no runner IP is whitelisted.
   - Status: **UNAVAILABLE / BLOCKED**.
5. **Deployed Architecture & Schema Identified (via Code Inspection):**
   - **Temporary extraction directory:** `Uploads/ApplicantStaging/{folderKey}/_tmp/` (where `folderKey` is SHA256 of session/token).
   - **Retained applicant source-document directory:** `Uploads/documents/{personnelId}/` (retained file name pattern: `{personnelId}_{docTypeId}_{guid}.{ext}`).
   - **Relevant applicant/personnel table:** `tbl_personnel_info` (`personnel_id`, `firstname`, `middlename`, `lastname`, `email_address`, `applicant_contact_num`, `crew_status`).
   - **Relevant personnel-document table:** `tbl_personnel_documents` (`id`, `personnel_id`, `document_id`, `document_num`, `date_issued`, `date_expiry`, `grade`, `img_id`).
   - **Link table and link-status fields:** `tbl_applicant_generated_link` (`id`, `link_token`, `fullname`, `email`, `status` ['Active' -> 'Used'], `validity`, `personnel_id`).

---

## 3. Test Case Summaries

### TC-CM-217: Temporary AI Artifact Cleanup
- **Requirement:** Confirm temporary OCR, conversion, page-image, and extraction-working files in staging are removed after extraction while source documents are preserved.
- **Evaluation:** Per the test mandate, if Kudu/server filesystem access is unavailable, the test must be marked **BLOCKED** and not passed through UI behavior alone.
- **Evidence Detail:** See [`tc217-file-inventory-sanitized.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/tc217-file-inventory-sanitized.md).

### TC-CM-219: No Premature AI Persistence
- **Requirement:** Take database snapshots at Checkpoints A (pre-upload), B (post-extraction), C (post-suggestion review), and D (post-submission). Verify 0 records in `tbl_personnel_info` and `tbl_personnel_documents` before final submission.
- **Evaluation:** Direct read-only MySQL queries are blocked by Azure firewall rules. Per the test mandate, marked **BLOCKED**.
- **Evidence Detail:** See [`tc219-database-checkpoints-sanitized.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/tc219-database-checkpoints-sanitized.md).

### TC-CM-220: Retained Applicant-Document Association
- **Requirement:** Verify submitted personnel document record, physical file existence/hash, protected handler 7-role access matrix, and direct static file denial.
- **Evaluation:** Database foreign-key inspection and physical file inspection via Kudu/SSH are blocked by Azure infrastructure constraints. Furthermore, live HTTP testing against Azure staging revealed that `/Crew/CrewDocumentHandler.ashx` returns HTTP 404 (file missing from deployed build). Direct static access to `/Uploads/documents/` is verified blocked (HTTP 404). Marked **BLOCKED**.
- **Evidence Detail:** See [`tc220-document-association-sanitized.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/tc220-document-association-sanitized.md).

### TC-CM-186: Secure Credential-Storage Database Evidence
- **Requirement:** Verify compliance with revised SR-04 (salted, adaptive password-hashing algorithm with configurable work factor; no plaintext, reversible encryption, or single-round hash).
- **Evaluation:** Codebase inspection confirms full implementation of PBKDF2-HMAC-SHA256 with 100,000 iterations and 256-bit salt in `CryptoHelper.vb`. Direct database schema inspection blocked by Azure MySQL firewall. Per mandate, status is **PASSED WITH TECHNICAL LIMITATION**.
- **Evidence Detail:** See [`tc186-credential-storage-sanitized.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/tc186-credential-storage-sanitized.md).

---

## 4. Cleanup & Data Isolation

- Established Cleanup Plan: Prefix `QA-C2-TECH-20261004`.
- Because server and database access were determined to be unavailable during preflight, no synthetic applicant records, links, or documents were written to the persistent database or retained storage.
- Active synthetic records remaining: `0`.
