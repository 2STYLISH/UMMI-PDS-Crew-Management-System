# UMMI Crew Management System — Cycle 2 Evidence Index (Reviewed Edition)

> **Document Status:** Authoritative Reviewed Edition (Reconciled with 142 Cycle 2 Cases and Packaged File Hierarchy)  
> **Environment:** Azure Staging (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`)  
> **Authoritative SRS Baseline:** [`documents/ByteMe SRS - UMMI.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/ByteMe%20SRS%20-%20UMMI.docx) (1,422,993 bytes | SHA-256: `96b220779905dd31f49083ad6606398812269825d4d0200a2657a0bca950ed45`)  
> **Authoritative Workbook with RTM:** [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Contains dedicated `RTM` tab with 11 columns)  
> **Authoritative Execution Workbook:** [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Worksheet: `Evidence`, 250 embedded images)  
> **Total Unique Test Cases Indexed:** **142 Cycle 2 Cases** (Master suite spans 229 distinct cases across Cycle 1 & 2)  
> **Link Resolution Standard:** All internal relative links verified to resolve from `qa/test-deliverables/documents/` into the packaged tree  
> **Superseded Prior Document:** `qa/test-deliverables/documents/cycle2-evidence-index.md` (Retained unchanged for audit history)

---

## 1. Index Architecture & Packaged File Hierarchy

This reviewed index maps every Cycle 2 test case directly to its physical artifact location within `qa/test-deliverables/`:
- **Shared batch reports:** `../evidence/shared/reports/<report-name>.md`
- **Execution telemetry:** `../evidence/shared/results/<result-name>.json`
- **Case-specific screenshots:** `../evidence/Cycle2/<Case-ID>/screenshots/<screenshot-name>.png`
- **Case-specific traces:** `../evidence/Cycle2/<Case-ID>/traces/<trace-name>.zip`
- **Historical defect captures:** `../evidence/history/defects/<defect-name>.png`
- **Historical reports:** `../evidence/history/reports/<report-name>.md`

---

## 2. Master Case Evidence Index (All 142 Test Cases)

| Test Case ID | Feature / Scenario | Requirement | Outcome | Evidence Mode | Packaged Primary Artifact Path | Verification Details & Telemetry Source |
| :--- | :--- | :--- | :---: | :--- | :--- | :--- |
| **TC-CM-002** | Per-user feature access | `FR-CM-51; FR-CM-53` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-002/screenshots/` | Manning control access and disabled redirects verified |
| **TC-CM-004** | Per-user feature access | `FR-CM-51; FR-CM-53` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-004/screenshots/` | Manning applicant pool denied redirect verified |
| **TC-CM-006** | Per-user feature access | `FR-CM-51; FR-CM-53` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-006/screenshots/` | Doc Officer control access verified |
| **TC-CM-008** | Per-user feature access | `FR-CM-51; FR-CM-53` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-008/screenshots/` | Doc Officer applicant pool denied redirect verified |
| **TC-CM-010** | Per-user feature access | `FR-CM-51; FR-CM-53` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-010/screenshots/` | Admin control access verified |
| **TC-CM-013** | Per-user feature access | `FR-CM-52; FR-CM-53` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-013/screenshots/` | Admin applicant pool denied redirect verified |
| **TC-CM-015** | Super-Admin bypass | `FR-CM-51; FR-CM-53` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-015/screenshots/` | Super-Admin non-editable always allowed bypass verified |
| **TC-CM-017** | Super-Admin bypass | `FR-CM-52; FR-CM-53` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-017/screenshots/` | Super-Admin applicant pool bypass verified |
| **TC-CM-019** | Applicant access | `FR-CM-52; FR-CM-53` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Principal rejected from applicant pool (HTTP 302/redirect) |
| **TC-CM-020** | Applicant access | `FR-CM-52; FR-CM-53` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Vessel Owner rejected from applicant pool (HTTP 302/redirect) |
| **TC-CM-021** | Crew search audit | `FR-CM-01; FR-CM-10` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Baseline grid search and activity log verified |
| **TC-CM-026** | Crew search by rank | `FR-CM-01` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Rank filter returns strictly matching crew records |
| **TC-CM-027** | Crew search by rank type | `FR-CM-01` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Officer vs Rating rank type filtering confirmed |
| **TC-CM-028** | Crew search by vessel | `FR-CM-01` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Assigned vessel isolates matching vessel records |
| **TC-CM-029** | Inactive search filter | `FR-CM-01` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-029/screenshots/` | Inactive status search filter isolation verified |
| **TC-CM-030** | City filter | `FR-CM-01` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-030/screenshots/` | City search filter verified across provinces |
| **TC-CM-031** | Vessel exp filter | `FR-CM-01` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-031/screenshots/` | Prior vessel experience filter confirmed |
| **TC-CM-032** | Cadetship filter | `FR-CM-01` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-032/screenshots/` | Cadetship program filter isolation confirmed |
| **TC-CM-033** | JOCAP filter | `FR-CM-01` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-033/screenshots/` | JOCAP training completion filter verified |
| **TC-CM-034** | Higher license filter | `FR-CM-01` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-034/screenshots/` | Higher license holder filtering verified |
| **TC-CM-035** | Combined criteria search | `FR-CM-01` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Conjunction of Name + Vessel + Rank verified |
| **TC-CM-036** | Availability date filter | `FR-CM-01` | **Passed** | Screenshot (10 img) | `../evidence/Cycle2/TC-CM-036/screenshots/` | Availability date range inclusive bounds verified |
| **TC-CM-041** | Principal status choices | `FR-CM-02` | **Passed** | Screenshot (3 img) | `../evidence/Cycle2/TC-CM-041/screenshots/` | Principal status choice restrictions verified |
| **TC-CM-042** | Principal vessel isolation | `FR-CM-03` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Unassigned vessel crew strictly hidden from Principal |
| **TC-CM-043** | Vessel Owner export hide | `FR-CM-05; FR-CM-25` | **Passed** | Headless Telemetry | `../evidence/shared/results/four-fix-rerun-results.json` | `btnExportExcel` hidden in DOM (`DEF-CM-002` verified) |
| **TC-CM-044** | Owner status choices | `FR-CM-02` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-044/screenshots/` | Vessel Owner status choice restrictions verified |
| **TC-CM-045** | Owner vessel isolation | `FR-CM-03` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Unassigned vessel crew strictly hidden from Owner |
| **TC-CM-046** | Unassigned account block | `FR-CM-03` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-046/screenshots/` | Zero vessel assignment returns zero records |
| **TC-CM-050** | Vessel visual grouping | `FR-CM-06` | **Passed** | Screenshot (21 img) | `../evidence/Cycle2/TC-CM-050/screenshots/` | Inline vessel grouping headers verified (`DEF-CM-016`) |
| **TC-CM-051** | Age calculation summary | `FR-CM-10` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-051/screenshots/` | Average age and total crew count calculation verified |
| **TC-CM-052** | Active 9M badge display | `FR-CM-07` | **Passed** | Screenshot (12 img) | `../evidence/Cycle2/TC-CM-052/screenshots/` | Active 9M badge display verified in profile viewer |
| **TC-CM-055** | Boundary badges check | `FR-CM-07` | **Passed** | Screenshot (3 img) | `../evidence/Cycle2/TC-CM-055/screenshots/` | Boundary badge edge conditions verified |
| **TC-CM-058** | Staff CCL roster nav | `FR-CM-08` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Manning Staff opens dedicated vessel roster |
| **TC-CM-059** | Doc Officer CCL nav | `FR-CM-08` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Doc Officer opens dedicated vessel roster |
| **TC-CM-060** | Admin CCL roster nav | `FR-CM-08` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Admin opens dedicated vessel roster |
| **TC-CM-061** | Super-Admin CCL nav | `FR-CM-08` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Super-Admin opens dedicated vessel roster |
| **TC-CM-062** | Unavailable CCL link hide | `FR-CM-08` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Unauthorized external users see no CCL entry point |
| **TC-CM-063** | Personnel info sheet | `FR-CM-11` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-063/screenshots/` | Personnel card rendering confirmed |
| **TC-CM-064** | Manning contact visible | `FR-CM-12; FR-CM-21` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-064/screenshots/` | Allowed contact details visible to Manning Staff |
| **TC-CM-065** | Manning contact hide | `FR-CM-12; FR-CM-21` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-065/screenshots/` | Restricted contact details hidden when flag is 0 |
| **TC-CM-067** | Doc Officer contact view | `FR-CM-12; FR-CM-21` | **Passed** | Screenshot (3 img) | `../evidence/Cycle2/TC-CM-067/screenshots/` | Doc Officer contact access verified |
| **TC-CM-068** | Doc Officer contact hide | `FR-CM-12; FR-CM-21` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-068/screenshots/` | Doc Officer restricted contact hidden |
| **TC-CM-069** | Admin contact view | `FR-CM-12; FR-CM-21` | **Passed** | Screenshot (3 img) | `../evidence/Cycle2/TC-CM-069/screenshots/` | Admin contact details visibility confirmed |
| **TC-CM-071** | Super-Admin contact view | `FR-CM-12; FR-CM-21` | **Passed** | Screenshot (3 img) | `../evidence/Cycle2/TC-CM-071/screenshots/` | Super-Admin contact details visibility confirmed |
| **TC-CM-073** | Principal contact hide | `FR-CM-12; FR-CM-21` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-073/screenshots/` | Principal contact details unconditionally masked |
| **TC-CM-074** | Owner profile guard | `FR-CM-12; FR-CM-21` | **Passed** | Screenshot (15 img) | `../evidence/Cycle2/TC-CM-074/screenshots/` | Direct profile URL parameter guard verified (`DEF-CM-019`) |
| **TC-CM-075** | Owner contact hide | `FR-CM-12; FR-CM-21` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-075/screenshots/` | Owner contact details unconditionally masked |
| **TC-CM-076** | BMI 1-decimal display | `FR-CM-13` | **Passed** | Screenshot (8 img) | `../evidence/Cycle2/TC-CM-076/screenshots/` | One-decimal BMI precision verified (`DEF-CM-017`) |
| **TC-CM-077** | BMI category classification | `FR-CM-13` | **Blocked** | Screenshot (9 img) | `../evidence/Cycle2/TC-CM-077/screenshots/` | Approved category color cutoffs undefined (`REQ-CM-002`) |
| **TC-CM-078** | SSS copy button | `FR-CM-14` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-078/screenshots/` | Clipboard copy operation confirmed |
| **TC-CM-079** | TIN copy button | `FR-CM-14` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-079/screenshots/` | Clipboard copy operation confirmed |
| **TC-CM-082** | HMO display without copy | `FR-CM-14` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-082/screenshots/` | HMO card displayed; copy button omitted per scope |
| **TC-CM-092** | Document expiry warning | `FR-CM-16` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-092/screenshots/` | Expiry warning indicator flags confirmed |
| **TC-CM-093** | Scanned document open | `FR-CM-17` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Protected attachment popup loads correctly |
| **TC-CM-094** | Unscanned document record | `FR-CM-15; FR-CM-17` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Record renders correctly without attachment binary |
| **TC-CM-096** | Sea service overlap merge | `FR-CM-18; FR-CM-19` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-096/screenshots/` | Interval deduplication verified (`DEF-CM-011`) |
| **TC-CM-098** | Ongoing sea service calc | `FR-CM-19` | **Failed** | Screenshot (9 img) | `../evidence/Cycle2/TC-CM-098/screenshots/` | **FAILED (Open):** 0.4 yr vs 0.5 yr PHT date mismatch (`DEF-CM-020`) |
| **TC-CM-099** | Unspecified PDS columns | `FR-CM-20` | **Out of Scope** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-099/screenshots/` | Scope decision: PDS-only extra columns retired |
| **TC-CM-100** | Read-only assessment | `FR-CM-21` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Assessment view is read-only |
| **TC-CM-101** | Empty assessment list | `FR-CM-21` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Handled gracefully when no records exist |
| **TC-CM-102** | Open assessment file | `FR-CM-22` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | HTTP 200 returned for assessment attachment |
| **TC-CM-103** | Benefit verification | `FR-CM-23; FR-CM-24` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-103/screenshots/` | Benefit verification & audit log verified (`DEF-CM-006`) |
| **TC-CM-104** | TIN verification | `FR-CM-23; FR-CM-24` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-104/screenshots/` | TIN verification & audit log verified (`DEF-CM-006`) |
| **TC-CM-117** | Releasing checklist access | `FR-CM-30` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-117/screenshots/` | Manning Staff checklist access verified |
| **TC-CM-122** | Applicant rank search | `FR-CM-33` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Applicant Pool rank search isolation confirmed |
| **TC-CM-123** | Applicant rank type search | `FR-CM-33` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Applicant Pool rank type isolation confirmed |
| **TC-CM-125** | Applicant date boundaries | `FR-CM-33` | **Passed** | Screenshot (3 img) | `../evidence/Cycle2/TC-CM-125/screenshots/` | Inclusive applicant creation date boundaries verified |
| **TC-CM-132** | Manual applicant creation | `FR-CM-36` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Manual applicant entry saved successfully |
| **TC-CM-133** | Manual applicant validation | `FR-CM-36` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Required field validation indicators verified |
| **TC-CM-134** | Synthetic applicant hiring | `FR-CM-37; FR-CM-38` | **Passed** | Screenshot (5 img) | `../evidence/Cycle2/TC-CM-134/screenshots/` | Hired applicant transitions to crew master table |
| **TC-CM-136** | Active encoding link | `FR-CM-39; FR-CM-40` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Generates active personalized token URL |
| **TC-CM-138** | Link name validation | `FR-CM-40` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Rejects missing applicant name |
| **TC-CM-139** | Link email validation | `FR-CM-40` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Rejects missing email address |
| **TC-CM-140** | Link validity validation | `FR-CM-40` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Rejects empty validity date |
| **TC-CM-141** | Link malformed email | `FR-CM-40` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Rejects malformed email syntax |
| **TC-CM-142** | Link invalid date | `FR-CM-40` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Rejects non-existent calendar date |
| **TC-CM-143** | Default link validity | `FR-CM-39; FR-CM-40` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Applies default 7-day validity |
| **TC-CM-144** | Compose email modal | `FR-CM-41` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-144/screenshots/` | Email modal opened; audit log recorded (`DEF-CM-006`) |
| **TC-CM-145** | Link status filtering | `FR-CM-42` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Active, Used, Expired status filters verified |
| **TC-CM-146** | Link sorting and 50-cap | `FR-CM-42` | **Passed** | Screenshot (3 img) | `../evidence/Cycle2/TC-CM-146/screenshots/` | Manage Links table displays latest 50 links |
| **TC-CM-147** | Link search filter | `FR-CM-42` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-147/screenshots/` | Name/email text search in Manage Links verified |
| **TC-CM-152** | Immutable link states | `FR-CM-44` | **Passed** | Screenshot (4 img) | `../evidence/Cycle2/TC-CM-152/screenshots/` | Terminal link states (Used/Expired) cannot be reverted |
| **TC-CM-160** | Resend active link | `FR-CM-47` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-160/screenshots/` | Resend retains token and opens email modal |
| **TC-CM-162** | Active link opens form | `FR-CM-48; FR-CM-50` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Active link opens scoped self-encoding wizard |
| **TC-CM-163** | Deny missing token | `FR-CM-48; FR-CM-49; SR-08` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Access denied without token query (`DEF-CM-003`) |
| **TC-CM-164** | Deny unknown token | `FR-CM-48; FR-CM-49; SR-08` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-164/screenshots/` | Routes to `AccessDenied.aspx` (`DEF-CM-003`) |
| **TC-CM-165** | Deny expired link | `FR-CM-48; FR-CM-49; SR-08` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-165/screenshots/` | Routes to `AccessDenied.aspx` (`DEF-CM-003`) |
| **TC-CM-166** | Deny used link | `FR-CM-48; FR-CM-49; SR-08` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-166/screenshots/` | Second access to submitted link denied |
| **TC-CM-167** | Deny elapsed validity | `FR-CM-48; FR-CM-49; SR-08` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-167/screenshots/` | Expired by calendar date denied (`DEF-CM-003`) |
| **TC-CM-168** | Session path restriction | `FR-CM-48` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Applicant session cannot browse staff URLs |
| **TC-CM-169** | Link natural expiry | `FR-CM-44; FR-CM-48; SR-08` | **Passed w/ Lim** | Screenshot (17 img) | `../evidence/Cycle2/TC-CM-169/screenshots/` | Natural expiry verified (`REQ-CM-003`) |
| **TC-CM-170** | Consume link on submit | `FR-CM-48` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Successful submit consumes token |
| **TC-CM-171** | Preserve valid inputs | `FR-CM-48` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Form validation retains user-typed data |
| **TC-CM-172** | Prevent duplicate submit | `FR-CM-48; SR-09` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Concurrent postback rejected |
| **TC-CM-181** | App Service latency | `PR-05` | **Passed** | Headless Telemetry | `../evidence/shared/results/tc181-performance-results.json` | Status transition p95 response time 488 ms (< 3000 ms) |
| **TC-CM-182** | Concurrent throughput | `PR-06` | **Passed w/ Lim** | Screenshot (3 img) | `../evidence/Cycle2/TC-CM-182/screenshots/` | Peak 100 VU load halted at 5m39s by Azure F1 quota (`INC-CM-001`) |
| **TC-CM-184** | UMMI role alignment | `SR-02` | **Passed** | Documentary Review | `../documents/cycle2-traceability-reviewed.md` | Role boundary alignment verified against `SR-02` |
| **TC-CM-185** | Supplier approval check | `SR-03 (Retired)` | **Out of Scope** | Specification Review | `../documents/cycle2-traceability-reviewed.md` | Requirement retired from current supplied SRS |
| **TC-CM-186** | PBKDF2 credential hash | `SR-04` | **Passed w/ Lim** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-186/screenshots/` | Code/login verified PBKDF2 100k rounds; DB audit pending (`EVD-CM-001`) |
| **TC-CM-187** | HTTPS transport redirect | `SR-05` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-187/screenshots/` | HTTP plaintext requests return 301 redirect to HTTPS |
| **TC-CM-188** | Response & path privacy | `SR-06` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Sensitive document paths omitted from responses (`DEF-CM-004`) |
| **TC-CM-189** | CCL open vessel roster | `FR-CM-79` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Manning Staff opens vessel roster in dedicated CCL |
| **TC-CM-190** | Display vessel roster | `FR-CM-79` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Roster correctly enumerates on-board crew |
| **TC-CM-191** | Select outgoing crew | `FR-CM-79` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Eligible outgoing crew member selected |
| **TC-CM-192** | Nominate reliever pool | `FR-CM-79` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-192/screenshots/` | Reliever pool modal verified (`DEF-CM-014`) |
| **TC-CM-193** | Approve reliever nomination | `FR-CM-79` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Reliever nomination approved |
| **TC-CM-194** | Reject reliever nomination | `FR-CM-79` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Reliever nomination rejected |
| **TC-CM-195** | Cancel nomination | `FR-CM-79` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Nomination cancelled |
| **TC-CM-196** | Create tentative schedule | `FR-CM-79` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-196/screenshots/` | Popup binds outgoing crew name (`DEF-CM-008`) |
| **TC-CM-197** | Bulk-apply schedule values | `FR-CM-79` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Bulk schedule date application confirmed |
| **TC-CM-198** | Finalize schedule & EOC | `FR-CM-79` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Schedule finalization and EOC generation confirmed |
| **TC-CM-199** | Prevent duplicate final | `FR-CM-79` | **Passed** | Headless Telemetry | `../evidence/shared/results/cycle2-final-results.json` | Re-finalization postback blocked |
| **TC-CM-200** | Amend finalized schedule | `FR-CM-79` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-200/screenshots/` | Amendment workflow and audit logging verified |
| **TC-CM-201** | Cancel schedule & EOC | `FR-CM-79` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-201/screenshots/` | Displays `Superseded` status (`DEF-CM-007`) |
| **TC-CM-202** | CCL permission checks | `FR-CM-79` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-202/screenshots/` | Role isolation enforced on CCL action controls |
| **TC-CM-203** | Record manual sign-on | `FR-CM-79` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-203/screenshots/` | Sign-on modal & On Board update verified (`DEF-CM-013`) |
| **TC-CM-204** | Verify CCL audit trail | `FR-CM-79` | **Passed** | Screenshot (1 img) | `../evidence/Cycle2/TC-CM-204/screenshots/` | Structured activity logs recorded (`DEF-CM-006`) |
| **TC-CM-205** | Optional AI encoding | `FR-CM-54; FR-CM-68` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-results.json` | Manual encoding remains fully available |
| **TC-CM-206** | Multi-document upload | `FR-CM-55` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-results.json` | Concurrently uploads resume, passport, and certificates |
| **TC-CM-207** | Upload formats & limits | `FR-CM-56; FR-CM-57; SR-10` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | PDF, JPG, PNG allowed; scripts/executables rejected |
| **TC-CM-208** | Native PDF & OCR parsing | `FR-CM-58; FR-CM-59` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | Native PDF parsing and OCR text extraction confirmed |
| **TC-CM-209** | Anti-hallucination extract | `FR-CM-60` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | Unstated fields remain blank without hallucinated values |
| **TC-CM-210** | Suggestion output schema | `FR-CM-61; FR-CM-62` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | Validated JSON schema mapped strictly to approved fields |
| **TC-CM-211** | Unmatched ref mapping | `FR-CM-63` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | Requires manual selection for unmapped ranks/vessels |
| **TC-CM-212** | Suggestion accept/reject | `FR-CM-64` | **Passed** | Screenshot (2 img) | `../evidence/Cycle2/TC-CM-212/screenshots/` | Explicit Reject button verified (`DEF-CM-009/010`) |
| **TC-CM-213** | Preservation on failure | `FR-CM-65` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-results.json` | Existing typed values preserved during extraction errors |
| **TC-CM-214** | Conflicting value display | `FR-CM-66` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | Conflicting values presented side-by-side with source tags |
| **TC-CM-215** | Approval before replace | `FR-CM-67` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | Explicit approval required before overwriting typed data |
| **TC-CM-216** | AI processing consent | `FR-CM-70` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-results.json` | Explicit consent banner presented before document ingestion |
| **TC-CM-217** | Ephemeral file cleanup | `FR-CM-69; SR-18` | **Passed** | Headless Telemetry | `../evidence/shared/reports/tc217-file-inventory-sanitized.md` | Ephemeral OCR artifacts cleaned; source docs retained |
| **TC-CM-218** | Privacy-safe audit logs | `FR-CM-71; SR-17` | **Passed** | Headless Telemetry | `../evidence/shared/results/targeted-regression-results.json` | Document events logged with zero PII/byte disclosure |
| **TC-CM-219** | Zero direct DB write | `FR-CM-72; SR-14` | **Passed** | Headless Telemetry | `../evidence/shared/reports/tc219-database-checkpoints-sanitized.md` | AI pipeline writes zero records directly to personnel tables |
| **TC-CM-220** | Retain original uploads | `FR-CM-73` | **Passed** | Documentation | `../evidence/shared/reports/tc220-document-association-sanitized.md` | Document retention documented (Handler view in `TC-CM-221`) |
| **TC-CM-221** | Authorized doc handler | `FR-CM-74; SR-12` | **Passed** | Screenshot (3 img) | `../evidence/Cycle2/TC-CM-221/screenshots/` | Protected handler serves HTTP 200 for staff (`DEF-CM-004/005`) |
| **TC-CM-222** | Atomic rollback integrity | `FR-CM-75` | **Unverified** | Telemetry | `../evidence/shared/results/ai-results.json` | Fault-injection transaction test unexecuted (`QA-CM-001`) |
| **TC-CM-223** | Source doc traceability | `FR-CM-76` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | Extracted fields link back to specific source page/doc |
| **TC-CM-224** | Review status badge | `FR-CM-77` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | Field review status badge (`Accepted`/`Rejected`) verified |
| **TC-CM-225** | Repeating record cards | `FR-CM-78` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | Repeating sea service/education cards parsed separately |
| **TC-CM-226** | Extraction duration cap | `PR-07` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-rerun-results.json` | Parsing duration satisfies latency cap (< 45s) |
| **TC-CM-227** | Provider error isolation | `PR-08; FR-CM-68` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-results.json` | Provider HTTP 5xx isolated gracefully with user fallback |
| **TC-CM-228** | Provider zero-retention | `SR-11; SR-13` | **Passed w/ Lim** | Headless Telemetry | `../evidence/shared/results/technical-evidence-results.json` | Technical controls verified; DPA document pending (`EVD-CM-002`) |
| **TC-CM-229** | Content safety validation | `SR-15; SR-16` | **Passed** | Headless Telemetry | `../evidence/shared/results/ai-results.json` | Non-document payloads and injection strings rejected |

---
*Reviewed and verified against authoritative test assets.*
