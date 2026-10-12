# TC-CM-217: Temporary AI Artifact Cleanup (Sanitized File Inventory & Evidence)

**Test Identifier:** TC-CM-217  
**Traceability:** FR-CM-69, FR-CM-73  
**Target Environment:** Azure Staging (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`)  
**Deployed Commit Tested:** `c737536`  
**Execution Date:** 2026-10-04  
**Data Prefix:** `QA-C2-TECH-20261004`  

---

## 1. Test Objective & Scope

Confirm that temporary AI-processing artifacts (intermediate rendered page PNGs, OCR caches, temporary extraction JSONs) are cleaned up immediately following extraction, while accepted source documents required for applicant review and final submission are preserved in session staging.

---

## 2. Server Access Preflight & Verification Limitation

Per the explicit test instructions:
> *"Through Kudu/SSH, record the relevant temporary and staging directories before upload... If the required Kudu/server or database access is unavailable, stop the affected test and report it as BLOCKED. Do not mark it Passed through UI behavior alone."*

### Preflight Diagnostics
1. **SCM / Kudu Endpoint DNS Resolution:**
   - Command: `dns.lookup('ummi-crew-hdccaegqbke9gwab.scm.azurewebsites.net')`
   - Result: `getaddrinfo ENOTFOUND ummi-crew-hdccaegqbke9gwab.scm.azurewebsites.net`
   - Diagnostic: The SCM/Kudu management endpoint is disabled or isolated from the public network on the Azure App Service.
2. **SSH Connection Capability:**
   - Test: `Test-Path ~/.ssh`
   - Result: `False` (no authorized SSH keys or tunnel configured on runner).
3. **Azure CLI (`az`):**
   - No interactive or automated Azure credentials authorized on the test runner.

**Preflight Outcome:** Server filesystem inspection via Kudu/SSH is **UNAVAILABLE**.

---

## 3. Deployed Architecture Analysis (Code-Level Verification)

Inspection of the deployed codebase reveals the exact server-side file lifecycle:

### A. Staging & Temporary Directory Structure
- **Root Staging Directory:** `~/Uploads/ApplicantStaging/`
- **Session-Specific Directory:** `~/Uploads/ApplicantStaging/{folderKey}/`
  - `folderKey` is a deterministic 16-character hex hash computed from `SHA256(tokenOrSessionId)` (see [`ApplicantStorageService.vb`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/CrewMgmt/App_Code/ApplicantStorageService.vb#L90-L103)).
- **Temporary OCR / Page Rendering Directory:** `~/Uploads/ApplicantStaging/{folderKey}/_tmp/`

### B. Immediate Cleanup Mechanism (FR-CM-69)
In [`DocumentExtractionService.vb`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/CrewMgmt/App_Code/DocumentExtractionService.vb#L188-L234):
- For multi-page PDF documents, each page is rasterized to a temporary PNG inside `{stagingDir}/_tmp/`.
- In line 227–233, an explicit `Finally` block executes:
  ```vb
  Finally
      ' FR-CM-69 GUARANTEE: Temporary PNG is deleted in this Finally block
      ' regardless of success, API error, timeout, or unhandled exception.
      If Not String.IsNullOrEmpty(tmpPngPath) Then
          ApplicantStorageService.DeleteTemporaryArtifacts(tmpPngPath)
      End If
  End Try
  ```
- This guarantees that intermediate visual page images are deleted immediately after each page is submitted to the AI vision endpoint.

### C. Staged Document Retention & Post-Submit Cleanup
- The source document uploaded by the applicant is retained as `{stagingDir}/{guidKey}.pdf`.
- Upon successful submission in `SelfEncode.aspx.vb`, accepted documents are promoted to `~/Uploads/documents/{personnelId}/` and the staging folder `{stagingDir}` is purged asynchronously via `HostingEnvironment.QueueBackgroundWorkItem`.
- Abandoned staging folders older than the configured threshold (default 7 days) are purged by `ApplicantStorageService.CleanupAbandonedStagingSessions()` (FR-CM-73).

---

## 4. Expected vs Sanitized File Inventory Model

| Stage | Path Pattern | Expected Content | Deployed Code Lifecycle |
|---|---|---|---|
| **Before Upload** | `Uploads/ApplicantStaging/` | Existing active sessions only | Session directory does not yet exist |
| **During Extraction** | `Uploads/ApplicantStaging/{folderKey}/` | `[GUID].pdf` (staged upload) | Preserved |
| **During Extraction** | `Uploads/ApplicantStaging/{folderKey}/_tmp/` | `page_*.png` (rasterized page images) | Created during OCR/vision step |
| **After Extraction** | `Uploads/ApplicantStaging/{folderKey}/_tmp/` | Empty / Deleted | Purged in `Finally` block of `DocumentExtractionService.vb` |
| **After Extraction** | `Uploads/ApplicantStaging/{folderKey}/` | `[GUID].pdf` (source file) | Preserved for form review |
| **After Submission** | `Uploads/documents/{personnelId}/` | `{personnelId}_{docTypeId}_{guid}.pdf` | Promoted permanent document |
| **After Submission** | `Uploads/ApplicantStaging/{folderKey}/` | Purged | Cleaned up via background worker |

---

## 5. Test Verdict

- **Status:** **BLOCKED**
- **Rationale:** While the code-level cleanup implementation in `DocumentExtractionService.vb` and `ApplicantStorageService.vb` satisfies FR-CM-69 and FR-CM-73, direct live server-side filesystem inspection via Kudu/SSH could not be executed due to the SCM endpoint being unavailable (`ENOTFOUND`). Per the mandate: *"If the required Kudu/server or database access is unavailable, stop the affected test and report it as BLOCKED. Do not mark it Passed through UI behavior alone."*
