# UMMI Playwright Test Suite — Phase 1 Accuracy Review & Execution Summary

> **Environment:** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`  
> **Browser:** Google Chrome (`channel: 'chrome'`)  
> **Workers:** 1 | **Retries:** 0 | **Execution Mode:** Read-Only  
> **Date:** October 01, 2026  
> **Test File:** `qa/playwright/tests/cycle2/phase1-readonly.spec.ts`  
> **Evidence Artifacts:**
> - HTML Report: `qa/playwright/playwright-report/index.html`
> - JSON Results: `qa/playwright/evidence/results.json`

---

## 1. Executive Summary

| Category | Count | Percentage |
| :--- | :---: | :---: |
| **Passed** | **7** | **28.0%** |
| **Failed** | **1** | **4.0%** |
| **Skipped** | **17** | **68.0%** |
| **Blocked** | **0** | **0.0%** |
| **Total Phase 1 Cases** | **25** | **100.0%** |

### Key Outcomes of Strict Accuracy Review
1. **Audit-Log Assertions Verified at Runtime:** `TC-CM-019`, `TC-CM-020`, and `TC-CM-021` now explicitly navigate to `/Settings/ActivityLogs.aspx` as Super-Admin and assert that the relevant Security and QueryCrew events were recorded.
2. **Strict Actor & Skip Reason for TC-CM-042:** Corrected actor mapping to Principal (`UMMI_PRINCIPAL_USER`). Because `QA Vessel A` does not exist and the Principal account is not isolated to a single assigned vessel, `TC-CM-042` is skipped for missing controlled vessel data (not restricted Manning).
3. **Rigorous Audit of TC-CM-188:** Verified against all 5 Excel steps. A full pass based solely on anonymous requests was rejected. Because `UMMI_MANNING_RESTRICTED_USER` is unconfigured and controlled out-of-scope attachment fixtures (`A001`/`B001`) are absent, `TC-CM-188` is accurately marked `SKIPPED`.
4. **Elimination of Weak Assertions & Real Personnel Substitution:** Tests that previously passed through weak checks (e.g. grid visibility, URL changes, or `typeof === 'boolean'`) or by substituting real personnel records for missing synthetic fixtures (`A001`, `A002`, `AP001`, `AP002`, `TD-LINKS`) have been downgraded to `SKIPPED`.
5. **Legitimate Application Defect Detected (TC-CM-043):** `TC-CM-043` failed because `btnExportExcel` is visible to Vessel Owner. Code inspection in `QueryCrew.aspx.vb` line 343 revealed `If Not IsPrincipal() Then btnExportExcel.Visible = (statusVal <> "5")`, which improperly displays the Export button for `ROLE_VESSEL_OWNER`. In accordance with instructions, this defect was not modified in code and remains recorded as a test failure.

---

## 2. Test Case Execution Results

| # | Test Case ID | Test Case Title | Role Used | Status | Duration | Strict Verification Details |
| :-: | :--- | :--- | :--- | :---: | :---: | :--- |
| 1 | **TC-CM-019** | Principal: reject internal Applicant Pool access | Principal / Super-Admin | `PASSED` | 3.5s | Menu link hidden; direct `/Applicant/ApplicantPool.aspx` redirected to `/Home.aspx`; Super-Admin verified Security audit log entry: `Attempted to access restricted page /Applicant/ApplicantPool.aspx`. |
| 2 | **TC-CM-020** | Vessel Owner: reject internal Applicant Pool access | Vessel Owner / Super-Admin | `PASSED` | 3.2s | Menu link hidden; direct `/Applicant/ApplicantPool.aspx` redirected to `/Home.aspx`; Super-Admin verified Security audit log entry. |
| 3 | **TC-CM-021** | Initial crew search and audit | Manning Staff / Super-Admin | `PASSED` | 3.7s | Initial load verified: Status defaults to ALL, search controls visible, summary count and data rows displayed; Super-Admin verified `QueryCrew` visit log in `ActivityLogs.aspx`. |
| 4 | **TC-CM-026** | Search by Rank | Manning Staff | `PASSED` | 4.8s | Step 1: Filtered by `AB SEAMAN`, asserted all returned rows contain `AB SEAMAN`. Step 2: Filtered by control rank `MASTER`, asserted all returned rows contain `MASTER` and exclude `AB SEAMAN`. |
| 5 | **TC-CM-027** | Search by Rank type | Manning Staff | `PASSED` | 4.9s | Step 1: Filtered by `Rating` with postback synchronization, asserted rows match rating ranks. Step 2: Filtered by control rank type `Deck`, asserted rows match deck ranks. |
| 6 | **TC-CM-028** | Search by Assigned vessel | Manning Staff | `PASSED` | 5.2s | Step 1: Filtered by `MT MINDANAO`, asserted assigned vessel column (td:4) contains `MT MINDANAO`. Step 2: Filtered by control vessel `MV CEBU PRIDE`, asserted column 4 contains `MV CEBU PRIDE` and excludes `MT MINDANAO`. |
| 7 | **TC-CM-035** | Combine crew name, vessel and rank | Manning Staff | `PASSED` | 3.1s | Combined search for Name `Aguilar` + Vessel `MT MINDANAO` + Rank `4TH ENGINEER`; asserted all returned rows match all three criteria simultaneously. |
| 8 | **TC-CM-042** | Principal: isolate assigned vessels | Principal | `SKIPPED` | 1.1s | *Missing controlled vessel data for QA Vessel A and Principal assignment.* |
| 9 | **TC-CM-043** | Vessel Owner: hide internal search controls | Vessel Owner | `FAILED` | 5.6s | **Defect:** `btnExportExcel` is visible for Vessel Owner. In `QueryCrew.aspx.vb` line 343, `If Not IsPrincipal()` only checks `ROLE_PRINCIPAL` and does not hide Export for `ROLE_VESSEL_OWNER`. |
| 10 | **TC-CM-045** | Vessel Owner: isolate assigned vessels | Vessel Owner | `SKIPPED` | 1.1s | *Missing controlled vessel data for QA Vessel A and Vessel Owner assignment.* (Weak assertion removed). |
| 11 | **TC-CM-058** | Manning Staff: open eligible vessel roster | Manning Staff | `SKIPPED` | 0ms | *Missing controlled synthetic crew fixtures A001/A002 on QA Vessel A.* |
| 12 | **TC-CM-059** | Documentation Officer: open eligible vessel roster | Documentation Officer | `SKIPPED` | 0ms | *Missing controlled synthetic crew fixtures A001/A002 on QA Vessel A.* |
| 13 | **TC-CM-060** | Admin: open eligible vessel roster | Admin | `SKIPPED` | 0ms | *Missing controlled synthetic crew fixtures A001/A002 on QA Vessel A.* |
| 14 | **TC-CM-061** | Super-Admin: open eligible vessel roster | Super-Admin | `SKIPPED` | 0ms | *Missing controlled synthetic crew fixtures A001/A002 on QA Vessel A.* |
| 15 | **TC-CM-062** | Hide unavailable CCL links | Manning Staff | `SKIPPED` | 0ms | *Missing controlled dataset for eligible/ineligible statuses, unassigned crew, and toggled CCL navigation permissions.* (Weak assertion removed). |
| 16 | **TC-CM-093** | Open correct scanned document | Manning Staff | `SKIPPED` | 0ms | *Controlled synthetic crew fixture A001 with QA-LIC attachment is not available in deployed staging database.* (Real personnel substitution removed). |
| 17 | **TC-CM-094** | Record without a scan | Manning Staff | `SKIPPED` | 0ms | *Controlled synthetic fixture A001 (TD-DOCS-NOSCAN) without attachment is not available in deployed staging database.* |
| 18 | **TC-CM-100** | Read-only assessment content | Manning Staff | `SKIPPED` | 0ms | *Controlled synthetic fixture A001 with TD-ASSESS notes is not available in deployed staging database.* |
| 19 | **TC-CM-101** | No assessment records | Manning Staff | `SKIPPED` | 0ms | *Controlled synthetic fixture A001 (TD-ASSESS-EMPTY) is not available in deployed staging database.* |
| 20 | **TC-CM-102** | Open assessment attachment | Manning Staff | `SKIPPED` | 0ms | *Controlled synthetic fixture A001 with A001-ASSESS attachment is not available in deployed staging database.* |
| 21 | **TC-CM-122** | Applicant search by Rank | Manning Staff | `SKIPPED` | 0ms | *Controlled synthetic applicant fixtures AP001 (QA Ana Reyes) and AP002 (QA Ben Cruz) are not available in deployed staging database.* |
| 22 | **TC-CM-123** | Applicant search by Rank type | Manning Staff | `SKIPPED` | 0ms | *Controlled synthetic applicant fixtures AP001 (QA Ana Reyes) and AP002 (QA Ben Cruz) are not available in deployed staging database.* |
| 23 | **TC-CM-145** | Link list fields and status filtering | Manning Staff | `SKIPPED` | 0ms | *Controlled TD-LINKS dataset (51 synthetic links including LA-FUTURE/LA-PAST/qa.ana@example.com) is not seeded in deployed staging database.* |
| 24 | **TC-CM-188** | Protected document and assessment access | Anonymous / Applicant / Staff | `SKIPPED` | 0ms | *Restricted Manning account without contact permission and controlled out-of-scope attachment fixtures (A001/B001) are not available.* |
| 25 | **TC-CM-202** | Enforce CCL action permissions | Various Roles | `SKIPPED` | 0ms | *Isolated synthetic crew-change fixtures required to safely execute and assert CCL workflow actions without mutating deployed data are not available.* |

---

## 3. Controlled Test Data Mapping Summary

| Test Case(s) | Specified Synthetic Fixtures (Excel) | Staging Status | Action Taken |
| :--- | :--- | :--- | :--- |
| **TC-CM-019, 020** | `demo.principal`, `demo.vesselowner`, `demo.superadmin` | Available | Executed UI denial & Super-Admin audit log assertion. |
| **TC-CM-021** | `demo.manning`, `demo.superadmin`, baseline active search | Available | Executed initial controls check & Super-Admin QueryCrew audit log assertion. |
| **TC-CM-026** | Rank `AB SEAMAN` (Match) / Rank `MASTER` (Control) | Available | Executed Step 1 & Step 2 with strict value assertions. |
| **TC-CM-027** | Rank Type `Rating` (Match) / Rank Type `Deck` (Control) | Available | Executed Step 1 & Step 2 with postback synchronization. |
| **TC-CM-028** | Vessel `MT MINDANAO` (Match) / Vessel `MV CEBU PRIDE` (Control) | Available | Executed Step 1 & Step 2 with column-4 assigned vessel assertions. |
| **TC-CM-035** | Name `Aguilar` + Vessel `MT MINDANAO` + Rank `4TH ENGINEER` | Available | Executed multi-criterion combination assertion. |
| **TC-CM-042, 045** | `QA Vessel A`, `QA Vessel B`, Principal/Owner isolated assignment | Missing | Skipped for missing controlled vessel data. |
| **TC-CM-058..061** | Synthetic crew `A001`, `A002` on `QA Vessel A` (On Board, Line Up, Vacation) | Missing | Skipped for missing controlled fixtures A001/A002. |
| **TC-CM-062** | Controlled mix of statuses, unassigned crew, permission toggle | Missing | Skipped for missing controlled dataset and permission toggles. |
| **TC-CM-093..102** | Synthetic `A001` with `QA-LIC`, `TD-DOCS-NOSCAN`, `TD-ASSESS`, `A001-ASSESS` | Missing | Skipped; real personnel records were NOT substituted. |
| **TC-CM-122, 123** | Synthetic applicants `AP001` (QA Ana Reyes), `AP002` (QA Ben Cruz) | Missing | Skipped for missing synthetic applicant fixtures. |
| **TC-CM-145** | `TD-LINKS` (51 synthetic links, `LA-FUTURE`, `qa.ana@example.com`) | Missing | Skipped for missing synthetic links dataset. |
| **TC-CM-188** | Restricted Manning (`viewcrewcontactdetails=0`), `A001`/`B001` attachments | Missing | Skipped for missing restricted account and controlled attachments. |
| **TC-CM-202** | Isolated synthetic crew change records | Missing | Skipped to prevent mutation of deployed staging data. |

---

## 4. Deployed Data Modification Safeguard Confirmation

- **Zero deployed records were created, updated, deleted, approved, rejected, or finalized on the deployed Azure application.**
- All executed test steps performed strictly read-only HTTP GET requests, search filter postbacks, and audit log inspection queries.
- No applicant links were generated, expired, or consumed.
- No CCL schedules were nominated, approved, or finalized.
- No database write operations were initiated.
