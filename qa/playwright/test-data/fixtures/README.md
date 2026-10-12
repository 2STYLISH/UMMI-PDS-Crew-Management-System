# UMMI Cycle 2 Phase 1 Synthetic Fixture Package

> **Target Environment:** Azure Staging Only (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`)  
> **Fixture Run Identifier:** `QA-C2-RUN-20261001-C2P1`  
> **Phase:** **Phase A (Preparation Only)** — Zero active execution or database modifications performed.  
> **Schema Assessment:** *Source-schema compatibility verified; live staging schema preflight still required.*  
> **Classification:** 100% Synthetic Test Artifacts — Zero Real PII  

---

## 1. Package Purpose & Scope

This fixture package provisions the controlled prerequisites required to unblock and execute the **17 skipped Phase 1 test cases** from the UMMI Cycle 2 test suite:

- **TC-CM-042:** Principal: isolate assigned vessels
- **TC-CM-045:** Vessel Owner: isolate assigned vessels
- **TC-CM-058:** Manning Staff: open eligible vessel roster
- **TC-CM-059:** Documentation Officer: open eligible vessel roster
- **TC-CM-060:** Admin: open eligible vessel roster
- **TC-CM-061:** Super-Admin: open eligible vessel roster
- **TC-CM-062:** Hide unavailable CCL links
- **TC-CM-093:** Open correct scanned document
- **TC-CM-094:** Record without a scan
- **TC-CM-100:** Read-only assessment content
- **TC-CM-101:** No assessment records
- **TC-CM-102:** Open assessment attachment
- **TC-CM-122:** Applicant search by Rank
- **TC-CM-123:** Applicant search by Rank type
- **TC-CM-145:** Link list fields and status filtering
- **TC-CM-188:** Protected document and assessment access
- **TC-CM-202:** Enforce CCL action permissions

---

## 2. Package File Manifest

| File Path | Description |
| :--- | :--- |
| `cycle2-fixture-preflight.sql` | **Live Schema Preflight Script:** Performs comprehensive read-only checks of required tables, columns, types, foreign keys, rank codes, and status enums. Zero state mutations. |
| `cycle2-fixture-setup.sql` | **Transactional Fixture Setup Script:** Wraps execution in stored procedure `sp_setup_qa_c2_run_20261001_c2p1` with `EXIT HANDLER FOR SQLEXCEPTION` (atomic rollback & resignal), pre-transaction `SIGNAL '45000'` precondition assertions, and post-execution cleanup. |
| `cycle2-fixture-validate.sql` | **Validation Verification Script:** Runs structured queries against exact run-specific keys, validating all 8 fixture areas and outputting `PASS`/`FAIL` indicators. |
| `cycle2-fixture-cleanup.sql` | **Exact-Key Cleanup Script:** Displays scheduled rows via pre-delete audits, deletes in reverse dependency order using exact run keys, and validates zero residual records remain. |
| `cycle2-fixture-manifest.json` | **Machine-Readable Mapping:** Maps every skipped test case to its required account, entities, vessel assignments, documents, dynamic dates, validation queries, and readiness state. |
| `README.md` | This technical guide, configuration reference, upload workflow, and orchestration checklist. |
| `documents/QA-C2-RUN-20261001-C2P1-LIC-A001.pdf` | Safe synthetic PDF scan (988 B) for crew `A001` license document tests. |
| `documents/QA-C2-RUN-20261001-C2P1-MED-A001.pdf` | Safe synthetic PDF scan (1001 B) for crew `A001` sensitive medical document tests. |
| `documents/QA-C2-RUN-20261001-C2P1-A001-ASSESS.pdf` | Safe synthetic PDF attachment (997 B) for crew `A001` assessment tests. |
| `documents/QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf` | Safe synthetic PDF attachment (970 B) for crew `B001` cross-vessel scope access tests. |

---

## 3. Strict Cleanup Isolation & Removal of Unsafe Clauses

In accordance with strict staging isolation requirements:
1. **Unsafe Clauses Removed:** The following overly broad conditions were eliminated:
   - `email LIKE '%@example.com'` (REMOVED)
   - `firstname LIKE 'QA%'` (REMOVED)
   - `personnel matching QA% OR @example.com` (REMOVED)
   - `fullname LIKE 'QA-C2%' without complete run identifier` (REMOVED)
2. **Exact Run-Specific Keys:** Cleanup queries target ONLY records tagged with the complete run identifier `QA-C2-RUN-20261001-C2P1` or exact fixture keys:
   - Vessels: `'QA-C2-RUN-20261001-C2P1-Vessel-A'`, `'QA-C2-RUN-20261001-C2P1-Vessel-B'`
   - Principal: `'QA-C2-RUN-20261001-C2P1-Principal-Shipping'`
   - Usernames: `'qa.c2.20261001.manning.restricted'`, `'qa.c2.20261001.principal'`, `'qa.c2.20261001.owner'`
   - Emails: `'qa-c2-20261001-a001@example.com'` through `'qa-c2-20261001-u001@example.com'`, `'qa-c2-20261001-ap001@example.com'`, `'qa-c2-20261001-ap002@example.com'`
   - Document Numbers: `'QA-C2-RUN-20261001-C2P1-LIC-A001-NUM'`, `'QA-C2-RUN-20261001-C2P1-MED-A001-NUM'`, `'QA-C2-RUN-20261001-C2P1-NOSCAN-A001-NUM'`, `'QA-C2-RUN-20261001-C2P1-LIC-B001-NUM'`
   - Filenames: `'QA-C2-RUN-20261001-C2P1-LIC-A001.pdf'`, `'QA-C2-RUN-20261001-C2P1-MED-A001.pdf'`, `'QA-C2-RUN-20261001-C2P1-A001-ASSESS.pdf'`, `'QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf'`
   - Links: `fullname LIKE 'QA-C2-RUN-20261001-C2P1%'` OR `link_token LIKE 'TOK-QA-C2-RUN-20261001-C2P1%'`
3. **Pre-Delete Audits:** Every deletion step in `cycle2-fixture-cleanup.sql` is preceded by an audit `SELECT` displaying the exact IDs and rows scheduled for removal.
4. **Post-Cleanup Residual Assertions:** An explicit verification query inspects all 7 core tables to assert that zero records with `RUN-20261001-C2P1` remain.

---

## 4. Live-Schema Preflight Verification

Before running fixture setup, execute:
```bash
mysql -h <host> -u <user> -p --database=<db> < qa/playwright/test-data/fixtures/cycle2-fixture-preflight.sql
```
`cycle2-fixture-preflight.sql` executes 9 read-only checks:
- **Check 1:** Presence of all 15 required application and lookup tables.
- **Check 2:** Presence and data types of key security, vessel assignment, and document columns.
- **Check 3:** Foreign key constraints between personnel, vessel, document, and schedule tables.
- **Check 4:** Availability of required user role codes (`MANNING_STAFF`, `PRINCIPAL`, `VESSEL_OWNER`).
- **Check 5:** Availability of crew status codes (`ACTIVE`, `INACTIVE`, `ON BOARD`, `ON VACATION`, `APPLICANT`, `LINE UP`).
- **Check 6:** Dynamic resolution of required ranks (`AB SEAMAN`, `BOSUN`, `3RD OFFICER`, `MASTER`, `4TH ENGINEER`, `CHIEF COOK`).
- **Check 7:** Dynamic resolution of required document categories (`License`, `Medical`, `Personal`).
- **Check 8:** Dynamic resolution of required vessel types (`Bulk Carrier`, `Container Ship`).
- **Check 9:** Overall Preflight Gate Decision: returns `PROCEED` or `ABORT`.

---

## 5. Dynamic Reference Resolution & Dynamic Dates

### 5.1 Dynamic Reference Resolution
`cycle2-fixture-setup.sql` never assumes hard-coded IDs:
```sql
SELECT id INTO @vtype_bulk FROM tbl_type_of_vessel WHERE typeOfVessel = 'Bulk Carrier' LIMIT 1;
SELECT id INTO @vtype_container FROM tbl_type_of_vessel WHERE typeOfVessel = 'Container Ship' LIMIT 1;
SELECT id INTO @rank_ab_seaman FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating' LIMIT 1;
SELECT id INTO @rank_bosun FROM tbl_rank WHERE rank_code = 'BOSUN' AND rank_type = 'Rating' LIMIT 1;
SELECT id INTO @doc_seaman_book FROM tbl_documents WHERE docType = 'License' AND documentName LIKE '%Seaman%Book%' LIMIT 1;
SELECT id INTO @doc_peme FROM tbl_documents WHERE docType = 'Medical' AND documentName LIKE '%PEME%' LIMIT 1;
```
If any required reference cannot be resolved or is missing, the script halts execution and rolls back immediately.

### 5.2 Dynamic Relative Dates
All operational and validity timestamps are calculated relative to `UTC_TIMESTAMP()`:
- **`LA-FUTURE`:** `DATE_ADD(UTC_TIMESTAMP(), INTERVAL 14 DAY)` (valid active state)
- **`LA-PAST1`:** `DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 DAY)` (expired validity -> triggers light-red table row highlighting in UI)
- **`LA-PAST2`:** `DATE_SUB(UTC_TIMESTAMP(), INTERVAL 2 DAY)` (expired validity -> triggers light-red table row highlighting in UI)
- **`LU-USED`:** `DATE_ADD(UTC_TIMESTAMP(), INTERVAL 7 DAY)`
- **`LE-EXPIRED`:** `DATE_SUB(UTC_TIMESTAMP(), INTERVAL 14 DAY)`
- **Document Issued Date:** `DATE_SUB(UTC_DATE(), INTERVAL 6 MONTH)`
- **Document Expiry Date:** `DATE_ADD(UTC_DATE(), INTERVAL 2 YEAR)`
- **HMO Expiry Date:** `DATE_ADD(UTC_DATE(), INTERVAL 1 YEAR)`
- **CCL Joining / Departure Date:** `DATE_ADD(UTC_DATE(), INTERVAL 30 DAY)`
- **CCL Onsign Date:** `DATE_ADD(UTC_DATE(), INTERVAL 31 DAY)`

---

## 6. Azure File Storage: Required Upload & Removal Sequence

### Background
`CrewDocumentHandler.ashx.vb` and `AssessmentAttachmentHandler.ashx.vb` resolve files directly from `Server.MapPath("~/Uploads/documents")` and `Server.MapPath("~/Uploads/assessments")`. Because the UMMI application does not expose an internal document upload form for existing crew members, database records alone will return HTTP 404 from handlers unless the physical files are placed on the server file system.

### Required Upload Sequence
```
1. Run cycle2-fixture-preflight.sql (Read-Only)
      │
2. Run cycle2-fixture-setup.sql (Database Setup)
      │
3. Retrieve generated personnel IDs for A001 and B001:
   SELECT id, firstname, lastname FROM tbl_personnel_info WHERE email_address IN ('qa-c2-20261001-a001@example.com', 'qa-c2-20261001-b001@example.com');
      │
4. Upload Personnel Documents ONLY into owning-crew folders (zero root fallbacks):
   - /site/wwwroot/Uploads/documents/<a001_id>/QA-C2-RUN-20261001-C2P1-LIC-A001.pdf
   - /site/wwwroot/Uploads/documents/<a001_id>/QA-C2-RUN-20261001-C2P1-MED-A001.pdf
   - /site/wwwroot/Uploads/documents/<b001_id>/QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf
      │
5. Upload Assessment Attachments ONLY into assessments directory:
   - /site/wwwroot/Uploads/assessments/QA-C2-RUN-20261001-C2P1-A001-ASSESS.pdf
   - /site/wwwroot/Uploads/assessments/QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf
   *(Note: There are 4 unique source PDFs in documents/, but 5 physical uploaded files because the B001 attachment supports both personnel-document and assessment testing scenarios).*
      │
6. Verify img_id in tbl_personnel_documents and tbl_personnel_comment match stored file names.
      │
7. Request protected handlers via authenticated HTTP GET and assert HTTP 200:
   - /Crew/CrewDocumentHandler.ashx?docID=<id>
   - /Crew/AssessmentAttachmentHandler.ashx?commentID=<id>
      │
8. Confirm direct static URLs (/Uploads/documents/... and /Uploads/assessments/...) are blocked:
   - Assert HTTP response status is either 403 (Forbidden) or 404 (Not Found), depending on IIS request filtering.
   - Assert zero document bytes are returned.
   - Assert Content-Type is not application/pdf or image/*.
   - Assert no server storage directory listing is disclosed.
```

### Exact File Removal Paths (Cleanup)
During cleanup, delete **only** the exact five synthetic physical files created for this run. **Never delete or truncate an entire Uploads directory or crew folder:**
- `/site/wwwroot/Uploads/documents/<a001_id>/QA-C2-RUN-20261001-C2P1-LIC-A001.pdf`
- `/site/wwwroot/Uploads/documents/<a001_id>/QA-C2-RUN-20261001-C2P1-MED-A001.pdf`
- `/site/wwwroot/Uploads/documents/<b001_id>/QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf`
- `/site/wwwroot/Uploads/assessments/QA-C2-RUN-20261001-C2P1-A001-ASSESS.pdf`
- `/site/wwwroot/Uploads/assessments/QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf`

---

## 7. Database and Filesystem Rollback Orchestration Checklist

> [!CAUTION]
> Database transactions cannot automatically roll back Kudu REST API or FTPS file uploads. The following orchestration checklist governs error handling and recovery across both state layers:

| Failure Scenario | Automatic Action | Manual Recovery Checklist |
| :--- | :--- | :--- |
| **Database Setup Failure** | Database transaction rolls back automatically (`ROLLBACK`). | Zero database changes persisted. No file uploads have occurred yet. Inspect SQL error and re-run preflight. |
| **File Upload Failure** | Upload script halts. | 1. Execute `DELETE` using Kudu VFS API for any of the 5 specific fixture paths uploaded.<br>2. Run `cycle2-fixture-cleanup.sql` to remove seeded database records.<br>3. Verify staging database returns to baseline. |
| **Handler Validation Failure** | Verification step reports failure before Playwright execution. | 1. Inspect App Service logs (`/LogFiles/eventlog.xml`).<br>2. Run `DELETE` via Kudu API for the 5 synthetic physical files.<br>3. Run `cycle2-fixture-cleanup.sql`. |
| **Test Execution Failure** | Playwright generates trace and screenshot evidence. | 1. Preserve Playwright trace artifacts.<br>2. Execute `cycle2-fixture-cleanup.sql` to clean database.<br>3. Remove the 5 synthetic physical files via Kudu API.<br>4. Run `cycle2-fixture-validate.sql` to confirm zero residual records. |

---

## 8. Account Provisioning Gate & Password Security Rules

### Approved Staging Provisioning Method
The 3 dedicated accounts must be provisioned following this exact staging gate:
- `qa.c2.20261001.manning.restricted`
- `qa.c2.20261001.principal`
- `qa.c2.20261001.owner`

#### Requirements:
1. **Locally Generated Temporary Password:** Create a unique, strong random staging password locally for this fixture run.
2. **Zero Password Reuse:** Do not reuse passwords or password hashes from demo accounts or any existing user.
3. **Zero Secret Exposure:** Do not place plaintext passwords, salts, or hashes in tracked repository files, SQL files, JSON manifests, or chat reports. Do not log credentials.
4. **Isolated Storage:** Store the credentials solely in the local, git-ignored `qa/playwright/.env` file.
5. **SR-04 Architectural Note:** The current application's authentication mechanism (SHA-256 with auto-upgrading salt in `login.aspx.vb`) is used strictly for temporary staging compatibility and **does not prove compliance with SR-04** (which requires Argon2id/PBKDF2 with high work factor and formal security review).
6. **Hard Gate:** If an approved staging provisioning mechanism or secure injection method is unavailable, **stop immediately**. Do not fall back to hardcoded default passwords.

#### Local Hash Calculation & Staging Injection:
```powershell
# Generate strong staging password and hash locally:
$pwd = "<staging_only_password>"
$sha = [System.Security.Cryptography.SHA256]::Create()
$hash = [BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($pwd))).Replace('-', '').ToLower()

# Inject into MySQL session variable without hardcoding in the SQL script:
mysql -h <host> -u <user> -p --database=<db> -e "SET @QA_PASSWORD_HASH='$hash'; SOURCE cycle2-fixture-setup.sql;"
```

#### Required Local Variables in `qa/playwright/.env` (Ignored):
```ini
UMMI_MANNING_RESTRICTED_USER=qa.c2.20261001.manning.restricted
UMMI_MANNING_RESTRICTED_PASSWORD=<staging_only_password>
UMMI_PRINCIPAL_USER=qa.c2.20261001.principal
UMMI_PRINCIPAL_PASSWORD=<staging_only_password>
UMMI_OWNER_USER=qa.c2.20261001.owner
UMMI_OWNER_PASSWORD=<staging_only_password>
```

---

## 9. Revalidated Test Mapping & Precondition Readiness

Every one of the 17 skipped Phase 1 cases was revalidated against the Excel workbook `Cycle2` worksheet:

| Test Case ID | Role | Required Fixtures | Readiness Status | Remaining Pre-Execution Requirement |
| :--- | :--- | :--- | :---: | :--- |
| **TC-CM-042** | Principal | `qa.c2.20261001.principal`, `Vessel-A`, `Vessel-B`, `A001`, `B001`, `U001` | **Ready** | Configure `UMMI_PRINCIPAL_USER` in `.env` |
| **TC-CM-045** | Vessel Owner | `qa.c2.20261001.owner`, `Vessel-A`, `Vessel-B`, `A001`, `B001`, `U001` | **Ready** | Configure `UMMI_OWNER_USER` in `.env` |
| **TC-CM-058** | Manning Staff | `Vessel-A`, `A001` (On Board), `A002` (Line Up), `A004` (Vacation) | **Ready** | None (uses `demo.manning`) |
| **TC-CM-059** | Doc Officer | `Vessel-A`, `A001` (On Board), `A002` (Line Up), `A004` (Vacation) | **Ready** | None (uses `demo.doc`) |
| **TC-CM-060** | Admin | `Vessel-A`, `A001` (On Board), `A002` (Line Up), `A004` (Vacation) | **Ready** | None (uses `demo.admin`) |
| **TC-CM-061** | Super-Admin | `Vessel-A`, `A001` (On Board), `A002` (Line Up), `A004` (Vacation) | **Ready** | None (uses `demo.superadmin`) |
| **TC-CM-062** | Manning / Restricted | `A001`, `A002`, `A003` (Inactive), `U001` (Unassigned) | **Ready** | None |
| **TC-CM-093** | Manning Staff | `A001`, `DOC-A001-LIC` (`QA-C2-RUN-20261001-C2P1-LIC-A001.pdf`) | **Pending Upload** | Upload PDF scan to `/site/wwwroot/Uploads/documents/` |
| **TC-CM-094** | Manning Staff | `A001`, `DOC-A001-NOSCAN` (`img_id = NULL`) | **Ready** | None (metadata-only record) |
| **TC-CM-100** | Manning Staff | `A001`, 2 Notes (1 with attachment, 1 without) | **Ready** | None |
| **TC-CM-101** | Manning Staff | `A004` (Vacation, exactly 0 assessment notes) | **Ready** | None |
| **TC-CM-102** | Manning Staff | `A001`, `ASSESS-A001-ATTACH` (`QA-C2-RUN-20261001-C2P1-A001-ASSESS.pdf`) | **Pending Upload** | Upload PDF attachment to `/site/wwwroot/Uploads/assessments/` |
| **TC-CM-122** | Manning Staff | `AP001` (`AB SEAMAN`, Rating), `AP002` (`3RD OFFICER`, Deck) | **Ready** | None |
| **TC-CM-123** | Manning Staff | `AP001` (Rating), `AP002` (Deck) | **Ready** | None |
| **TC-CM-145** | Manning Staff | Exactly 51 links, `LA-FUTURE` (+14d), `LA-PAST` (-1d/-2d), `LU-USED`, `LE-EXPIRED` | **Ready** | None |
| **TC-CM-188** | Multiple Roles | `A001` Medical & License, `B001` Attachment, Restricted Manning account | **Pending Upload** | Upload 4 PDFs to Uploads; configure `.env` |
| **TC-CM-202** | Multiple Roles | `Vessel-A`, Outgoing `A001`, Reliever `A002`, Tentative Schedule | **Ready** | None (read-only action inspection) |

---

## 10. Safety Safeguards Confirmation

- [x] **Zero Staging Execution in Phase A:** Zero SQL statements, zero HTTP PUT file uploads, and zero configuration changes were initiated against Azure Staging.
- [x] **Strict Run Isolation:** All synthetic entities are prefixed with `QA-C2-RUN-20261001-C2P1`.
- [x] **Zero Broad Purging:** Broad matching (`%@example.com`, `QA%`) has been completely removed.
- [x] **Dynamic Reference Resolution:** All foreign keys and types are dynamically resolved from the database schema.
- [x] **Dynamic Relative Dates:** All operational dates are computed relative to UTC execution time.
