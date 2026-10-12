# Formal Cycle 2 Batch 18 Gap-Closure Audit & Execution Summary

**Target Environment:** Azure Staging (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`)  
**Audit & Reconciliation Date:** October 11, 2026 (PHT)  
**Execution Profile:** Google Chrome (`Desktop Chrome`), 1 worker, 0 retries, serial sequential execution  
**Configuration File:** [`qa/playwright/playwright.batch18-gap.config.ts`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/playwright.batch18-gap.config.ts)  
**Test Spec:** [`qa/playwright/tests/cycle2/batch18-gap-closure.spec.ts`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/tests/cycle2/batch18-gap-closure.spec.ts)  
**Machine-Readable Results:** [`qa/playwright/evidence/batch18-gap-closure-results.json`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/batch18-gap-closure-results.json)  

---

## 1. Dated Correction Note (October 11, 2026)

> [!NOTE]
> **Audit Reconciliation Notice:**
> The initial Batch 18 execution report headline mistakenly stated *"11 cases / 13 executions"*. This discrepancy arose from a mislabeled headline in the prior reporting summary that conflated distinct test case IDs with execution counters.
>
> 1. **Inventory Reconciliation:** The test suite contains exactly **13 distinct test case IDs** (`TC-CM-030`, `TC-CM-031`, `TC-CM-032`, `TC-CM-033`, `TC-CM-034`, `TC-CM-046`, `TC-CM-050`, `TC-CM-055`, `TC-CM-076`, `TC-CM-092`, `TC-CM-125`, `TC-CM-134`, and `TC-CM-152`). In the initial run, each of these 13 cases was executed once (13 total executions).
> 2. **TC-CM-050 Classification Audit:** The initial test execution asserted Photo, Name, Rank, Status, Vessel, and Age, but omitted live assertions for Status Date, Availability, Last Vessel, and Sea-Service Duration. Per audit directive, TC-CM-050 was classified as **INCOMPLETE** (not PASSED). On October 11, 2026, a focused test execution was conducted asserting all 10 displayed fields across Vessel B and Unassigned seafarers, as well as the Vessel A/B/unassigned grouping. With all 10 fields and grouping requirements verified, TC-CM-050 is now classified as **PASSED**.
> 3. **TC-CM-076 Status:** Remains **FAILED** due to Azure staging returning integer BMI `22` rather than `22.2` for height 180 cm and weight 72 kg. All original screenshots, failure traces, and error context files are strictly preserved.

---

## 2. Reconciled Totals & Inventory Breakdown

| Metric | Prior to Audit & Retest | Post-Audit & Focused Retest | Notes |
| :--- | :---: | :---: | :--- |
| **Distinct Test Cases** | **13** | **13** | Exactly 13 distinct requirement case IDs in Batch 18 |
| **Total Test Executions** | **13** | **14** | 13 initial suite executions + 1 focused TC-CM-050 execution |
| **Passed Cases** | **11** | **12** | 11 initial + TC-CM-050 verified |
| **Failed Cases** | **1** | **1** | TC-CM-076 (BMI precision on live staging) |
| **Incomplete Cases** | **1** | **0** | TC-CM-050 resolved via focused execution |

### Distinct Case Inventory Breakdown

| # | Case ID | Module / Feature | Initial Execution Status | Post-Audit Status | Evidence Artifacts |
|---|---|---|---|---|---|
| 1 | **TC-CM-030** | QueryCrew: City Filtering | PASSED | PASSED | [`tc030-city-batangas-search.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc030-city-batangas-search.png)<br>[`tc030-city-manila-reversed-search.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc030-city-manila-reversed-search.png) |
| 2 | **TC-CM-031** | QueryCrew: Vessel Type Exp | PASSED | PASSED | [`tc031-bulk-carrier-exp-search.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc031-bulk-carrier-exp-search.png)<br>[`tc031-container-ship-exp-reversed-search.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc031-container-ship-exp-reversed-search.png) |
| 3 | **TC-CM-032** | QueryCrew: Cadetship Flag | PASSED | PASSED | [`tc032-cadetship-filtered.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc032-cadetship-filtered.png)<br>[`tc032-cadetship-cleared.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc032-cadetship-cleared.png) |
| 4 | **TC-CM-033** | QueryCrew: JOCAP Flag | PASSED | PASSED | [`tc033-jocap-filtered.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc033-jocap-filtered.png)<br>[`tc033-jocap-cleared.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc033-jocap-cleared.png) |
| 5 | **TC-CM-034** | QueryCrew: Higher License | PASSED | PASSED | [`tc034-higher-lic-filtered.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc034-higher-lic-filtered.png)<br>[`tc034-higher-lic-cleared.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc034-higher-lic-cleared.png) |
| 6 | **TC-CM-046** | QueryCrew: Unassigned Principal | PASSED | PASSED | [`tc046-unassigned-principal-zero-crew.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc046-unassigned-principal-zero-crew.png) |
| 7 | **TC-CM-050** | QueryCrew: Vessel Grouping & Fields | INCOMPLETE *(partial assertions)* | **PASSED** *(verified)* | [`tc050-focused-vessel-b-all-fields.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc050-focused-vessel-b-all-fields.png)<br>[`tc050-focused-unassigned-all-fields.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc050-focused-unassigned-all-fields.png)<br>[`tc050-focused-trace.zip`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/traces/tc050-focused-trace.zip) |
| 8 | **TC-CM-055** | QueryCrew: Status Duration Warning | PASSED | PASSED | [`tc055-status-duration-boundaries.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc055-status-duration-boundaries.png) |
| 9 | **TC-CM-076** | ProfileViewer: BMI Calculation | **FAILED** | **FAILED** | [`tc076-bmi-a001-normal.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc076-bmi-a001-normal.png)<br>[`tc076-failure-trace.zip`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/traces/tc076-failure-trace.zip)<br>[`test-failed-1.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/test-results/batch18-gap-closure-Cycle--0ce6f--suppress-BMI-without-error-chrome/test-failed-1.png) |
| 10 | **TC-CM-092** | QueryCrew: Doc Expiry Boundaries | PASSED | PASSED | [`tc092-doc-expiry-boundaries.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc092-doc-expiry-boundaries.png) |
| 11 | **TC-CM-125** | ApplicantPool: Date Filtering | PASSED | PASSED | [`tc125-applicant-date-filter-sep.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc125-applicant-date-filter-sep.png) |
| 12 | **TC-CM-134** | ApplicantPool: Confirm Hire Audit | PASSED | PASSED | [`tc134-hire-target-confirmed.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc134-hire-target-confirmed.png)<br>[`tc134-hired-crew-active-in-querycrew.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc134-hired-crew-active-in-querycrew.png)<br>[`tc134-hire-audit-entry-verified.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc134-hire-audit-entry-verified.png) |
| 13 | **TC-CM-152** | ManageApplicantLinks: Lifecycle | PASSED | PASSED | [`tc152-link-transitioned-to-expired.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc152-link-transitioned-to-expired.png)<br>[`tc152-terminal-state-immutability.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc152-terminal-state-immutability.png) |

---

## 3. TC-CM-050 Field-by-Field Audit & Verification

### 3.1 Audit Discovery & Rationale
In the initial Batch 18 run, `TC-CM-050` verified vessel dropdown filtering (Vessel A vs. Vessel B) and asserted 6 row fields:
- Photo (`imgCrewPhoto`)
- Name (`lnkProfile`)
- Rank (`MASTER`)
- Status (`ON BOARD`)
- Vessel Name (`QA-C2-RUN-20261001-C2P1-Vessel-B`)
- Age (`40`)

However, the complete test requirement mandates asserting all **10 displayed grid columns**, specifically including:
1. **Status Date**
2. **Availability**
3. **Last Vessel**
4. **Sea-Service Duration**
5. **Vessel A, Vessel B, and Unassigned Grouping**

Because these assertions were absent from the initial spec and unrecorded in the initial trace, TC-CM-050 was classified as **INCOMPLETE**.

### 3.2 Focused Test Execution
A dedicated focused execution was performed against Azure staging without touching QA fixtures:
- **Command:** `npx playwright test tests/cycle2/batch18-gap-closure.spec.ts -g "TC-CM-050" --config=playwright.batch18-gap.config.ts --reporter=list --trace on`
- **Duration:** 6.4 seconds
- **Result:** **PASSED (10/10 fields verified + Vessel A/B/unassigned grouping confirmed)**
- **Dedicated Trace:** [`qa/playwright/evidence/traces/tc050-focused-trace.zip`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/traces/tc050-focused-trace.zip)

### 3.3 Field-by-Field Verification Results

| # | Column / Field | Target DOM Element | Observed Value (Vessel B Crew) | Observed Value (Unassigned Crew) | Verification Status |
|---|---|---|---|---|---|
| 1 | **Photo** | `img[id*="imgCrewPhoto"]` | Image rendered with class `crew-photo-cell status-onboard` | Image rendered with class `crew-photo-cell status-active` | **PASSED** |
| 2 | **Name** | `a[id*="lnkProfile"]` | `"QA2B18_VesselBCrew, Andres Bonifacio"` (Link to `ProfileViewer.aspx`) | `"QA2B18_UnassignedCrew, Lucas Perez"` (Link to `ProfileViewer.aspx`) | **PASSED** |
| 3 | **Rank** | `td:nth-child(3)` | `"MASTER"` | `"3RD OFFICER"` | **PASSED** |
| 4 | **Status** | `td:nth-child(4)` | `"ON BOARD"` | `"ACTIVE"` | **PASSED** |
| 5 | **Vessel** | `td:nth-child(5)` | `"QA-C2-RUN-20261001-C2P1-Vessel-B"` (`a.vessel-link` to `VesselCrew.aspx`) | `""` (Empty string; unassigned seafarer has no assigned vessel) | **PASSED** |
| 6 | **Age** | `td:nth-child(6)` | `"40"` | `"34"` | **PASSED** |
| 7 | **Last Vessel** | `span[id*="lblLastVessel"]` | `""` (Attached; empty in live grid) | `""` (Attached; empty in live grid) | **PASSED** |
| 8 | **Status Date** | `span[id*="lblStatusDate"]` | `"08/10/2026"` | `"09/15/2026"` | **PASSED** |
| 9 | **Sea Service** | `span[id*="lblSeaService"]` | `"1.0 yr(s)"` | `"1.0 yr(s)"` | **PASSED** |
| 10 | **Availability** | `td:nth-child(10)` | `"Not Available"` (`span.badge-used`) | `"Available"` (`span.badge-active`) | **PASSED** |

### 3.4 Vessel Grouping Verification

1. **QA Vessel A Grouping:**
   - Filter `drpdwnVessel = QA-C2-RUN-20261001-C2P1-Vessel-A`, search `LastName = QA2B18`.
   - Grid contains `QA2B18_BatangasMatch`.
   - Grid cleanly excludes `QA2B18_VesselBCrew` and `QA2B18_UnassignedCrew`.
2. **QA Vessel B Grouping:**
   - Filter `drpdwnVessel = QA-C2-RUN-20261001-C2P1-Vessel-B`, search `LastName = QA2B18`.
   - Grid contains `QA2B18_VesselBCrew`.
   - Grid cleanly excludes `QA2B18_BatangasMatch` and `QA2B18_UnassignedCrew`.
3. **Unassigned Grouping:**
   - Filter `drpdwnVessel = ALL`, search `LastName = QA2B18_UnassignedCrew`.
   - Returns `QA2B18_UnassignedCrew` with Rank `3RD OFFICER`, Status `ACTIVE`, Vessel cell empty `""`, Availability `Available`.

---

## 4. TC-CM-076 Failure Evidence Retention

- **Test Case ID:** `TC-CM-076`
- **Status:** **FAILED (Application Precision Defect on Staging)**
- **Observed Behavior on Live Staging:**
  - Tested Profile: `Santos, QA Maria` (Biometrics: Height 180 cm, Weight 72 kg).
  - Formula: $\text{BMI} = \frac{72}{(1.80)^2} = 22.2222\dots \approx 22.2$.
  - Expected Display: `22.2` (with 1-decimal precision per SRS / Cycle 2 specification).
  - Received Display on Azure Staging: **`22`** (integer display).
  - Assertion Failure: `Error: BMI expected 22.2 with 1 decimal precision. Received: "22"`.
- **Biometric Suppression Controls:**
  - Blank biometrics seafarer (`QA2B18_BmiBlank`): BMI and Classification cleanly suppressed as `""` without application error.
  - Zero biometrics seafarer (`QA2B18_BmiZero`): BMI and Classification cleanly suppressed as `""` without application error.
- **Preserved Staging Evidence Paths:**
  - Live Failure Screenshot: [`test-failed-1.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/test-results/batch18-gap-closure-Cycle--0ce6f--suppress-BMI-without-error-chrome/test-failed-1.png)
  - Profile Biometrics Screenshot: [`tc076-bmi-a001-normal.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc076-bmi-a001-normal.png)
  - Blank Suppression Screenshot: [`tc076-bmi-blank-suppressed.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc076-bmi-blank-suppressed.png)
  - Zero Suppression Screenshot: [`tc076-bmi-zero-suppressed.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/tc076-bmi-zero-suppressed.png)
  - Full Execution Trace: [`qa/playwright/evidence/traces/tc076-failure-trace.zip`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/traces/tc076-failure-trace.zip)
  - Test-Results Trace: [`qa/playwright/test-results/batch18-gap-closure-Cycle--0ce6f--suppress-BMI-without-error-chrome/trace.zip`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/test-results/batch18-gap-closure-Cycle--0ce6f--suppress-BMI-without-error-chrome/trace.zip)
  - Error Context: [`error-context.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/test-results/batch18-gap-closure-Cycle--0ce6f--suppress-BMI-without-error-chrome/error-context.md)

---

## 5. Artifacts and Evidence File Paths

### Evidence & Trace Files
- **Reconciled JSON Results:** [`qa/playwright/evidence/batch18-gap-closure-results.json`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/batch18-gap-closure-results.json)
- **Batch 18 Summary Report:** [`qa/playwright/evidence/batch18-gap-closure-summary.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/batch18-gap-closure-summary.md)
- **TC-CM-050 Focused Trace:** [`qa/playwright/evidence/traces/tc050-focused-trace.zip`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/traces/tc050-focused-trace.zip)
- **TC-CM-076 Failure Trace:** [`qa/playwright/evidence/traces/tc076-failure-trace.zip`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/traces/tc076-failure-trace.zip)

### Preserved Screenshots Directory
- Full Directory: [`qa/playwright/evidence/screenshots/cycle2/batch18/`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/screenshots/cycle2/batch18/)
  - `tc030-city-batangas-search.png`
  - `tc030-city-manila-reversed-search.png`
  - `tc031-bulk-carrier-exp-search.png`
  - `tc031-container-ship-exp-reversed-search.png`
  - `tc032-cadetship-filtered.png`
  - `tc032-cadetship-cleared.png`
  - `tc033-jocap-filtered.png`
  - `tc033-jocap-cleared.png`
  - `tc034-higher-lic-filtered.png`
  - `tc034-higher-lic-cleared.png`
  - `tc046-unassigned-principal-zero-crew.png`
  - `tc050-grouping-vessel-a.png`
  - `tc050-grouping-vessel-b.png`
  - `tc050-displayed-fields-verified.png`
  - `tc050-focused-vessel-b-all-fields.png` *(new separate focused screenshot)*
  - `tc050-focused-unassigned-all-fields.png` *(new separate focused screenshot)*
  - `tc055-status-duration-boundaries.png`
  - `tc076-bmi-a001-normal.png`
  - `tc076-bmi-a001.png`
  - `tc076-bmi-blank-suppressed.png`
  - `tc076-bmi-calculation-rounded.png`
  - `tc076-bmi-zero-suppressed.png`
  - `tc092-doc-expiry-boundaries.png`
  - `tc125-applicant-date-filter-sep.png`
  - `tc134-hire-target-confirmed.png`
  - `tc134-hired-crew-active-in-querycrew.png`
  - `tc134-hire-audit-entry-verified.png`
  - `tc152-link-transitioned-to-expired.png`
  - `tc152-terminal-state-immutability.png`

---

## 6. Files Changed & Integrity Compliance

### Files Changed
1. [`qa/playwright/tests/cycle2/batch18-gap-closure.spec.ts`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/tests/cycle2/batch18-gap-closure.spec.ts): Enhanced `TC-CM-050` with assertions for all 10 displayed columns (photo, name, rank, status, vessel, age, last vessel, status date, sea service, availability) for Vessel B crew and unassigned crew, saving separate screenshots.
2. [`qa/playwright/evidence/batch18-gap-closure-results.json`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/batch18-gap-closure-results.json): Updated machine-readable results with audit reconciliation block and TC-CM-050 focused execution attachments.
3. [`qa/playwright/evidence/batch18-gap-closure-summary.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/playwright/evidence/batch18-gap-closure-summary.md): Documented reconciled totals, audit discovery, field-by-field verification, and preserved failure evidence.
4. Scratch file `qa/playwright/scratch/inspect-tc050.js` (used for diagnostic DOM cell inspection).

### Integrity Compliance Confirmation
- Application source code (`CrewMgmt/`): **ZERO changes**.
- SQL fixtures and migrations (`*.sql`): **ZERO changes**.
- SRS specifications and Excel workbooks: **ZERO changes**.
- QA2B18 fixtures and test accounts: **ZERO cleanup or modification executed**.
- Failure history and artifacts: **All original failure screenshots and traces preserved intact**.
