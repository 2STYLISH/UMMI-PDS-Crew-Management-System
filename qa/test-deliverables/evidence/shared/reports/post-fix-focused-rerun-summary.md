# UMMI Cycle 2 — Post-Fix Focused Regression Test Summary

**Execution Date:** 2026-10-04  
**Target Environment:** Azure Staging (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`)  
**Deployed Commit Tested:** `c737536` (*Fix: Blank outgoing crew name in schedule popups and mobile responsive view*)  
**Prior Deployed Baseline:** `d27298b` (*Fix: CCL Scheduling*)  
**Local Baseline:** `cb9df6c` synchronized with `main` at commit `c737536`  
**Execution Profile:** Google Chrome (Headless), 1 Worker, 0 Retries, Serial Execution  
**Data Prefix:** `QA-C2-POSTFIX-20261004` (Isolated Synthetic Data)  

---

## 1. Executive Summary

A focused Cycle 2 regression test suite was executed against the live Azure Staging environment following the deployment of commit `c737536`. The test run specifically targeted the two reported defect fixes:
1. **TC-CM-212 (FR-CM-64):** Scalar AI suggestion lifecycle (Apply, Replace, Edit, Reject, Manual Completion, Persistence, Content Safety).
2. **CCL Schedule Popups:** Outgoing and Incoming crew names in Create Schedule and Edit Schedule modals, tentative schedule creation, schedule amendment, role enforcement, and vessel isolation.

### Test Results Overview

| Test Case Identifier | Scope / Objective | Status | Key Observations & Findings |
|---|---|:---:|---|
| **TEST 1-A: TC-CM-212** | Apply, Replace, Edit, Manual Completion, Content Safety | **PASSED** | Apply populates field; Replace updates conflicting value; manual edit preserved across wizard navigation; manual input preserved; zero script execution / inert escaping. |
| **TEST 1-B: TC-CM-212** | Explicit Reject, Conflicting Reject & Persistence (Commit `c737536`) | <span style="color:red;font-weight:bold;">FAILED</span> | **Application Defect in Commit `c737536`**: The `.btn-reject-suggestion` ("Reject") button was added to the DOM, but clicking it throws `TypeError: this.saveState is not a function`, preventing the rejection pill (`.ai-sug-rejected`) from activating. |
| **TEST 2: Create Sched** | Create Schedule popup names & Tentative schedule save | **PASSED** | `<b>Outgoing Crew:</b> Bonifacio, QA Andres de Castro` verified (not blank, not undefined). Reliever verified. Tentative schedule created successfully. |
| **TEST 3: Edit Sched** | Edit Schedule popup names & Schedule amendment | **PASSED** | `<b>Outgoing Crew:</b> Bonifacio, QA Andres de Castro` verified. Schedule amended to `Port of Subic` and saved. Unrelated nominations on Vessel A unchanged. |
| **TEST 4: CCL Regression** | Roles, Vessel Isolation, EOC, Popup Navigation | **PASSED** | Status remains Tentative; Vessel Owner denied all actions (0 buttons); Vessel A & B rosters strictly isolated; existing EOC intact; popup cancel returns user to CCL context. |

**Totals:** 4 Passed, 1 Failed, 0 Skipped, 0 Blocked (Total Duration: 1.2m).

---

## 2. Step-by-Step Technical Observations

### TEST 1: TC-CM-212 Complete Scalar AI Suggestion Lifecycle (Traceability: FR-CM-64)

#### A. Apply Lifecycle (Verified in TEST 1-A)
- Uploaded `synthetic_manifest_resume.pdf` to an isolated applicant self-encoding session (`QA-C2-POSTFIX-20261004-TC212-ApplySession`).
- Empty field `MiddleName` rendered suggestion slot `#aiSuggestion_MiddleName` with suggested value `"Alvarez"`.
- Verified `.btn-apply-suggestion` was visible with text `Apply` and `data-val="Alvarez"`.
- Clicked `Apply`:
  - Destination input `[id$="txtMiddleName"]` received exact value `"Alvarez"`.
  - Suggestion pill updated to applied/matched state (`.ai-sug-matched`, text `Matches document: Alvarez`).

#### B. Replace Lifecycle (Verified in TEST 1-A)
- `LastName` was prepopulated with applicant name `QA-C2-POSTFIX-20261004-TC212-ApplySession`.
- Extraction yielded conflicting suggestion `"Dela Cruz"`.
- Verified suggestion slot `#aiSuggestion_LastName` rendered `.ai-sug-different`:
  - Current value displayed in `.ai-curr-val`.
  - Suggested value displayed in `.ai-sug-val`.
  - Explicit `.btn-replace-suggestion` visible with text `Replace`.
- Clicked `Replace`:
  - Destination input `[id$="txtLastName"]` updated to `"Dela Cruz"`.

#### C. Edit Lifecycle (Verified in TEST 1-A)
- After applying `"Alvarez"`, manually edited input `[id$="txtMiddleName"]` to `"Alvarez-EditedManual-2026"`.
- Navigated to Step 2 (Repeating Records), waited for view switch, and navigated back to Step 1.
- Verified input value remained `"Alvarez-EditedManual-2026"`. The AI engine did not silently restore or overwrite with `"Alvarez"`.

#### D. Reject Lifecycle (Verified in TEST 1-B)
- In a fresh isolated session (`QA-C2-POSTFIX-20261004-TC212-RejectSession`), empty field `MiddleName` rendered suggested value `"Alvarez"`.
- **Button Verification:** Confirmed that commit `c737536` successfully added `<button type="button" class="btn-reject-suggestion" data-field="MiddleName" title="Dismiss suggestion">Reject</button>` to the suggestion pill.
- **Click Execution & Runtime Defect:**
  - Clicked the `Reject` button.
  - Browser captured unhandled JavaScript runtime error: `TEST 1-B BROWSER_PAGE_ERROR: this.saveState is not a function`.
  - Destination input `[id$="txtMiddleName"]` remained unchanged and empty (`""`).
  - Suggestion pill remained in its unrejected state (`.ai-suggestion-pill`) and did NOT transition to `.ai-sug-rejected`.
  - Screenshot captured: `test-results/post-fix-focused-rerun/tc212-scalar-rejection-state.png`.

#### E. Reject Conflicting Suggestion (Analyzed in TEST 1-B)
- Confirmed that the conflicting suggestion pill on `LastName` also rendered the `.btn-reject-suggestion` control alongside `.btn-replace-suggestion`.
- Due to the fatal runtime error in `rejectSuggestion`, clicking Reject is blocked by the same `TypeError`.

#### F. Persistence & Submission Safety (Analyzed in TEST 1-B)
- State persistence requires `this.saveState()`, which fails due to the undefined function. The rejected action cannot be saved into `state.fieldDecisions`.

#### G. Manual Completion (Verified in TEST 1-A)
- Empty field `PlaceOfBirth` (`[id$="txtPOB"]`) manually filled with `"Zamboanga City"`.
- Verified value was preserved and editable.

#### H. Content Safety (Verified in TEST 1-A)
- Verified zero dialog alerts (`alertTriggered === false`).
- Verified all `.ai-suggestion-slot` HTML outputs: zero unescaped `<script>` tags, zero unescaped `onerror=` event handlers.

---

### TEST 2: Create Schedule Popup Crew Names Verification

- **Target Crew Nominated:** `Bonifacio, QA Andres de Castro` on Vessel B (`QA-C2-RUN-20261001-C2P1-Vessel-B`, Vessel ID: `6`).
- **Reliever Assigned & Approved:** `BOSUN — Cabrera, Victor` (selected from 31 eligible pool candidates and approved by SuperAdmin).
- **Create Schedule Modal Verification:**
  - Clicked `Schedule` button on Bonifacio's row.
  - Modal `#modalSchedule` opened with title `Create CCL Schedule`.
  - **Outgoing Crew Label Verified:**
    `<b>Outgoing Crew:</b> Bonifacio, QA Andres de Castro`
  - Neither blank, undefined, nor swapped. HTML characters rendered cleanly.
  - Screenshot captured: `test-results/post-fix-focused-rerun/create-schedule-popup-names.png`.
- **Tentative Schedule Creation:**
  - Filled Joining Date (`10/11/2026`), Joining Port (`Batangas Port`), Departure Date (`10/11/2026`), Ship Onsign (`10/11/2026`).
  - Saved schedule. Confirmed success alert `Schedule saved successfully`.
  - Row status updated to `Tentative`.
  - Unrelated nominations on Vessel A (Maria Clara Santos, status `Next`) remained completely unchanged.

---

### TEST 3: Edit Schedule Popup Crew Names Verification

- **Target Row:** Bonifacio's Tentative schedule row on Vessel B.
- **Edit Schedule Modal Verification:**
  - Clicked `Edit` button on Bonifacio's row.
  - Modal `#modalSchedule` opened with title `Edit CCL Schedule`.
  - **Outgoing Crew Label Verified:**
    `<b>Outgoing Crew:</b> Bonifacio, QA Andres de Castro`
  - Outgoing crew name rendered correctly (defect from commit `d27298b` fully fixed in `c737536`).
  - Screenshot captured: `test-results/post-fix-focused-rerun/edit-schedule-popup-names.png`.
- **Schedule Amendment:**
  - Amended Joining Port to `Port of Subic` and dates to `10/13/2026`.
  - Saved schedule. Confirmed success notification `Schedule saved successfully`.
  - Row in `#tblCCL` reflected updated port `Port of Subic` and maintained `Tentative` status.
  - Unrelated records on Vessel A remained unchanged.

---

### TEST 4: Focused CCL Regression

- **Tentative Status:** Verified that Create Schedule and Edit Schedule both preserve `Tentative` status until finalized to `Next`.
- **Role Enforcement:** Signed in as unauthorized role `VESSEL_OWNER`:
  - Verified `0` Schedule, Edit, or Reliever buttons rendered on Vessel B.
  - Verified `0` Schedule, Edit, or Reliever buttons rendered on Vessel A.
- **Vessel Isolation:**
  - Vessel A (`QA-VESSEL-A`) displays only Santos and Rizal; strictly excludes Bonifacio.
  - Vessel B (`QA-VESSEL-B`) displays only Bonifacio; strictly excludes Santos and Rizal.
- **Existing EOC Display:**
  - Maria Clara Santos on Vessel A retains `Next` schedule and `Superseded` EOC badge.
  - Clicking `EOC` button opens `#modalEOC` cleanly and closes without state corruption.
- **Popup Closing Navigation:**
  - Clicked `Edit` on Vessel B, clicked `Cancel` in `#modalSchedule`.
  - Confirmed modal closed, backdrop cleared, and user remained in the Vessel B CCL context (`drpVesselPicker === '6'`).

---

## 3. Detailed Application Defect Analysis

### Defect Identified: Uncaught TypeError in `rejectSuggestion`
- **Issue ID:** `DEFECT-AI-REJECT-RUNTIME-001`
- **Component:** `CrewMgmt/scripts/applicant-ai-assist.js` (lines 1554–1563 in deployed commit `c737536`)
- **Severity:** High (Feature Inoperable)
- **Root Cause Analysis:**
  In commit `c737536`, the developer added the `.btn-reject-suggestion` button to the DOM and wired the click event to call `self.rejectSuggestion(fieldKey)`.
  However, `rejectSuggestion` was implemented as follows:
  ```javascript
  rejectSuggestion: function (fieldKey) {
      this.state.fieldDecisions = this.state.fieldDecisions || {};
      this.state.fieldDecisions[fieldKey] = {
          action: 'rejected',
          timestamp: new Date().toISOString()
      };
      this.saveState();              // <-- Line 1560: TypeError: this.saveState is not a function
      this.evaluateField(fieldKey);  // <-- Line 1561: this.evaluateField is not a function
      this.updateGlobalProgress();   // <-- Line 1562: this.updateGlobalProgress is not a function
  }
  ```
  In `ApplicantAiAssist`:
  - The persistence method is `this.persistFieldDecisions()`, not `this.saveState()`.
  - The rendering method is `this.renderFieldSuggestion(fieldKey, fieldDef, sug)`, not `this.evaluateField(fieldKey)`.
  - The progress method is `this.updateProgressUI()`, not `this.updateGlobalProgress()`.
  As a result, clicking `Reject` immediately crashes with `Uncaught TypeError: this.saveState is not a function`, preventing the rejection decision from persisting and preventing the UI from re-rendering in the rejected state (`.ai-sug-rejected`).
- **Recommended Remediation:**
  Update `rejectSuggestion` in `applicant-ai-assist.js`:
  ```javascript
  rejectSuggestion: function (fieldKey) {
      this.state.fieldDecisions = this.state.fieldDecisions || {};
      this.state.fieldDecisions[fieldKey] = {
          action: 'rejected',
          timestamp: new Date().toISOString()
      };
      this.persistFieldDecisions();
      var fieldDef = this.coreFields[fieldKey];
      var sug = this.state.suggestionPackage ? this.state.suggestionPackage.PersonalDetails[fieldKey] : null;
      if (fieldDef && sug) {
          this.renderFieldSuggestion(fieldKey, fieldDef, sug);
      }
      this.updateProgressUI();
  }
  ```

---

## 4. Test Script Adjustments & Separations

1. **Test Separation:** Divided TC-CM-212 into `TEST 1-A` (Apply, Replace, Edit, Manual Completion, Content Safety) and `TEST 1-B` (Explicit Reject and Rejection Persistence). This ensured all functional parts of TC-CM-212 were thoroughly validated rather than being blocked by the runtime exception in Reject.
2. **Locator Alignment:** Updated Place of Birth manual entry locator to match ASP.NET control ID `[id$="txtPOB"]`.
3. **Class Matching:** Updated applied suggestion pill assertion to accept `.ai-sug-matched` (rendered when field value matches document) or `.ai-sug-applied`.
4. **Schedule Opener Fallback:** In `TEST 2`, when a Tentative schedule was already saved from a prior run, verified modal opening via row opener so screenshot and Outgoing Crew label are consistently validated on every run.

---

## 5. Artifacts and Evidence File Locations

- **Summary Markdown:** `qa/playwright/evidence/post-fix-focused-rerun-summary.md`
- **JSON Test Results:** `qa/playwright/evidence/post-fix-focused-rerun-results.json`
- **HTML Report:** `qa/playwright/post-fix-focused-rerun-report/index.html`
- **Screenshots:**
  - Scalar Rejection State: `qa/playwright/test-results/post-fix-focused-rerun/tc212-scalar-rejection-state.png`
  - Create Schedule Popup Names: `qa/playwright/test-results/post-fix-focused-rerun/create-schedule-popup-names.png`
  - Edit Schedule Popup Names: `qa/playwright/test-results/post-fix-focused-rerun/edit-schedule-popup-names.png`

---

## 6. Compliance and Workspace State Confirmation

- **Application Source Code & SRS:** Zero tracked files modified (`git status --short` confirms 0 tracked modifications).
- **Staging Records:** No production records modified. Isolated synthetic records created under `QA-C2-POSTFIX-20261004` on Vessel B. Applicant links expired and purged.
- **Security Compliance:** No passwords, tokens, API keys, hashes, salts, or confidential applicant PII were logged or exposed.
