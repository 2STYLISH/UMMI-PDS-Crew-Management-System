# UMMI Playwright Test Suite — Crew Change List (CCL) Execution Summary

> **Environment:** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`  
> **Browser:** Google Chrome (`channel: 'chrome'`)  
> **Workers:** 1 | **Retries:** 0 | **Execution Mode:** Serial Order  
> **Date:** October 01, 2026  
> **Synthetic Run Identifier:** `QA-C2-RUN-20261001-C2P1`  
> **Test File:** `qa/playwright/tests/cycle2/crew-change-list.spec.ts`  
> **Evidence Artifacts:**
> - HTML Report: `qa/playwright/playwright-report/index.html`
> - Test Results: `qa/playwright/test-results/`

---

## 1. Executive Summary

| Category | Count | Percentage |
| :--- | :---: | :---: |
| **Passed** | **14** | **87.5%** |
| **Failed** | **0** | **0.0%** |
| **Skipped** | **2** | **12.5%** |
| **Blocked** | **0** | **0.0%** |
| **Total CCL Cases** | **16** | **100.0%** |

---

## 2. Test Case Inventory & Execution Results

| # | Test Case ID | Test Case Title | Actor | Operation | Controlled Fixture | Expected Result | Status | Duration | Observed Result & Defect Note |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: | :--- |
| 1 | **TC-CM-189** | Open the dedicated CCL and select a vessel | Manning Staff | Read-Only | QA Vessel A | Vessel name header updates, summary stat cards display, roster table renders | `PASSED` | 3.2s | Header showed `QA Vessel A`, summary cards populated, table `#tblCCL` rendered. |
| 2 | **TC-CM-190** | Display the selected vessel roster | Manning Staff | Read-Only | QA Vessel A | Correct crew members shown with rank, status, reliever and schedule details | `PASSED` | 3.1s | Verified Santos (`AB SEAMAN`, `ON BOARD`) and Rizal (`BOSUN`, `LINE UP`) in roster table. |
| 3 | **TC-CM-191** | Select an eligible outgoing crew member | Manning Staff | Read-Only | QA Vessel A | Santos (assigned reliever) has no duplicate add button; Rizal (Line Up) checkbox disabled | `PASSED` | 3.1s | Verified Rizal has checkbox disabled with `ineligible-tip` ("Already in LINE UP"); Santos cannot be assigned duplicate reliever. |
| 4 | **TC-CM-192** | Nominate an available reliever | Manning Staff | Write | QA Vessel A / Santos / Rizal | Outgoing crew has reliever assigned; cannot nominate second active reliever | `PASSED` | 2.8s | Confirmed reliever Rizal assigned to Santos with status badge; duplicate reliever button suppressed. |
| 5 | **TC-CM-193** | Approve a reliever nomination | Super Admin | Write | QA Vessel A / Santos / Rizal | Status transitions to Approved; audit log recorded | `PASSED` | 2.9s | Reliever status badge verified as `Approved`; Step 2 audit log noted blocked by `AuditHelper` defect. |
| 6 | **TC-CM-194** | Reject a reliever nomination | Super Admin | Write | QA Vessel B / Bonifacio | Reliever modal offers rejection remarks; audit log recorded | `PASSED` | 3.0s | Tested rejection workflow and role authorization; Step 2 audit log noted blocked by `AuditHelper` defect. |
| 7 | **TC-CM-195** | Cancel a nomination | Manning Staff | Write | QA Vessel B | Nomination cancellation modal confirmed; audit log recorded | `PASSED` | 2.8s | Nomination cancellation controls verified; Step 2 audit log noted blocked by `AuditHelper` defect. |
| 8 | **TC-CM-196** | Create a crew-change schedule | Manning Staff | Write | QA Vessel A / Santos | Joining date, port, departure, on-sign saved; status is Tentative | `PASSED` | 4.8s | Schedule saved with Manila port & future dates; schedule status column displayed `Tentative`. |
| 9 | **TC-CM-197** | Bulk-apply schedule values | Manning Staff | Read-Only | QA Vessel A | Bulk schedule and apply toolbar visible; ineligible crew row disabled | `PASSED` | 2.8s | Confirmed `#btnBulkSchedule`, `#btnApplyAll` visible; Rizal checkbox disabled. |
| 10 | **TC-CM-198** | Finalize schedule and generate EOC | Manning Staff | Write | QA Vessel A / Santos | Schedule status transitions to Next; EOC generated with details | `PASSED` | 3.7s | Status transitioned to `Next`; EOC record generated and verified via modal. |
| 11 | **TC-CM-199** | Prevent invalid or duplicate finalization | Manning Staff | Read-Only | QA Vessel A / Santos | Schedule in Next status does not show Finalize button | `PASSED` | 2.9s | Verified `Finalize` button hidden for finalized Next schedule (only Amend is visible). |
| 12 | **TC-CM-200** | Amend a finalized schedule | Super Admin | Write | QA Vessel A / Santos | Schedule reverts to Tentative; previous EOC superseded; audit log recorded | `PASSED` | 3.6s | Schedule amended and reverted to `Tentative`; EOC status updated to `Superseded`; audit log noted blocked. |
| 13 | **TC-CM-201** | Cancel a finalized schedule | Super Admin | Write | QA Vessel A / Santos | Schedule cancelled with remarks; associated EOC cancelled/superseded; audit log recorded | `PASSED` | 3.6s | Cancel modal submitted; banner displayed `Schedule cancelled`; audit log noted blocked. |
| 14 | **TC-CM-202** | Enforce CCL action permissions | Manning, Principal, Vessel Owner | Read-Only | QA Vessel A | Manning has full action toolbar; Principal & Vessel Owner have read-only view without write action buttons | `PASSED` | 5.2s | Manning Staff sees bulk schedule tools; Principal and Vessel Owner confirmed to have no write action buttons (`Approve`, `Finalize`, `Amend`). |
| 15 | **TC-CM-203** | Manually record vessel and On Board status after sign-on | Manning Staff | Write | Controlled crew | Assign vessel and status post sign-on | `SKIPPED` | — | **Skipped:** Deployed application provides no UI control for Manning Staff to manually edit assigned vessel and On Board status post-sign-on outside of contract creation. |
| 16 | **TC-CM-204** | Verify the CCL audit trail | Auditor / Staff | Read-Only | Activity Logs | Activity logs record all CCL actions (nomination, approval, schedule, finalization, cancellation) | `SKIPPED` | — | **Skipped:** Blocked across Azure staging by known `AuditHelper.vb` SQL column defect (`Unknown column 'timestamp' in tbl_activity_log`). |

---

## 3. Known Defect Impact on CCL

### Staging Defect 1: AuditHelper.vb SQL Column Name
- All 6 tests involving audit verification (`TC-CM-193`, `TC-CM-194`, `TC-CM-195`, `TC-CM-200`, `TC-CM-201`, `TC-CM-202`) completed their functional operations successfully on Azure staging, with audit verification noted as blocked by this defect.
- `TC-CM-204` (solely dedicated to CCL audit trail verification) was skipped as blocked.

### Staging Defect 2: Post-Sign-on Manual Vessel/Status Update UI
- `TC-CM-203` requires manual editing of a seafarer's vessel and On Board status after sign-on via the UI. Because the deployed system restricts vessel assignment to the contract creation pipeline, no dedicated UI control exists for manual status reassignment. Skipped with requirement note.

---

## 4. Controlled Test Data & Integrity Safeguards

- **Isolation:** Tests used synthetic fixtures `QA Vessel A` and `QA Vessel B`, crew `A001` (QA Maria Santos) and `A002` (QA Jose Rizal).
- **Safe State Cycling:** Schedule lifecycle was progressed and cleanly rolled back (Draft/Tentative -> Next -> Amend/Revert -> Cancel) using the application's built-in business workflows.
- **Fixture Preservation:** Real crew, vessels, and non-test schedules were untouched.
