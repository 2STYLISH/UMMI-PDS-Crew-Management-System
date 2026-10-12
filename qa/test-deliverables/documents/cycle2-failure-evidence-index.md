# Cycle 2 Failure Evidence Index

> **Document Status:** Historical Failure Observations & Diagnostic Evidence Index  
> **Authoritative SRS Baseline:** [`documents/ByteMe SRS - UMMI.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/ByteMe%20SRS%20-%20UMMI.docx) (1.42 MB, SHA-256 `96b22077...`)  
> **Authoritative Workbooks:** [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) and [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx)  
> **Audit Principle:** Historical failure observations are preserved accurately to explain diagnostic context, while distinguishing recorded test execution outcomes from full requirement acceptance.

This document catalogs all defects, runtime failures, and interruptions encountered during Cycle 2 testing, preserving complete context, evidence locations, and post-fix resolution statuses.

---

## 1. TC-CM-212: AI Suggestion Rejection Runtime Defect (`TypeError: this.saveState is not a function`)

- **Test Case ID:** TC-CM-212
- **Title:** AI Suggestion Review and Explicit Scalar Rejection Lifecycle
- **Status:** **RESOLVED / PASSED (Previously Failed, Fixed and Verified)**
- **Original Failing Deployed Commit:** `c737536`
- **Fix Commit (Repo / PR):** `b323bcd` ("AI suggestion rejection runtime defect", authored Sun Oct 4 19:37:00 2026 +0800)
- **Deployed Build Verified:** `97fd151` (Live IIS asset ETag `"0fc4148054dd1:0"`, Last-Modified `Sun, 04 Oct 2026 13:00:08 GMT` / 21:00 PHT)
- **Actor / Role:** Applicant (Self-Encoding Session via generated link)
- **Exact Failed Step:** Step 1-B / Reject Suggestion (`.btn-reject-suggestion` click)
- **Original Failure:**
  - Clicking the Reject button threw unhandled exception:
    `TypeError: this.saveState is not a function at Object.rejectSuggestion (applicant-ai-assist.js:315)`
  - Suggestion remained un-rejected and unpersisted.
- **Resolution & Post-Fix Verification:**
  - Deployed commit `97fd151` replaced invalid method calls with `this.recordFieldDecision(fieldKey, 'rejected', null)`, `this.renderFieldSuggestion(slot, fieldKey, fieldDef, sug)`, and `window.updateReview()`.
  - Retest verified both ordinary scalar rejection and conflicting-value rejection cleanly transition to `.ai-sug-rejected`, display `"Rejected:"` badge, leave target destination inputs untouched, persist across wizard step navigation, and trigger zero JavaScript errors.
- **Preserved Evidence Locations:**
  - Original Failure Screenshot (state): `qa/playwright/test-results/tc212-final-retest/tc212-original-failure-scalar-rejection-state.png`
  - Original Failure Screenshot (closeup): `qa/playwright/test-results/tc212-final-retest/tc212-original-failure-scalar-rejection-closeup.png`
  - Post-Fix Verified Rejection Screenshot: `qa/playwright/test-results/tc212-final-retest/tc212-postfix-verified-scalar-rejection.png`
  - Post-Fix Verified Full Page Screenshot: `qa/playwright/test-results/tc212-final-retest/tc212-postfix-verified-fullpage.png`
  - Post-Fix Summary: `qa/playwright/evidence/tc212-final-retest-summary.md`
  - Post-Fix JSON Results: `qa/playwright/evidence/tc212-final-retest-results.json`

---

## 2. TC-CM-181 (PR-03-B): Dynamic ASP.NET Client ID Locator Mismatch (Interrupted / Resolved)

- **Test Case ID:** TC-CM-181
- **Operation:** PR-03-B: Applicant-Link Status Transition
- **Status:** **RESOLVED / PASSED (488 ms p95)**
- **Interruption Context:**
  - In initial performance runs, status transitions failed because ASP.NET GridView rendered client IDs ending in sequential row indices (e.g., `..._gvLinks_drpdwnNewStatus_0`).
  - An exact ends-with selector (`select[id$="drpdwnNewStatus"]`) failed to match the rows.
  - Furthermore, checking `isVisible()` immediately while an ASP.NET postback was executing caused intermittent timeouts.
- **Resolution:**
  - Updated locator selector to contains-syntax: `select[id*="drpdwnNewStatus"]` and `a[id*="btnUpdateStatus"]`.
  - Added explicit visibility wait `ddl.waitFor({ state: 'visible', timeout: 8000 })` and postback settlement quiet window (400 ms) outside measured time.
- **Rerun Evidence:**
  - 20 of 20 measured runs passed cleanly with 0 failures.
  - 95th-percentile response time: **488 ms** (Threshold: &le; 3000 ms).
  - Summary: `qa/playwright/evidence/tc181-performance-summary.md`
  - JSON Results: `qa/playwright/evidence/tc181-performance-results.json`

---

## 3. TC-CM-217, TC-CM-219, TC-CM-220: Technical Infrastructure Verification Limitations

- **Test Case IDs:**
  - `TC-CM-217` (Document Retention & 30-Day Purge Lifecycle / `SR-18`)
  - `TC-CM-219` (Database State Checkpoints / `SR-14`)
  - `TC-CM-220` (Document Association & Retention / `FR-CM-73`)
- **Status in Historical Observation:** **BLOCKED (Azure Direct Infrastructure Access Unavailable)**
- **Reconciliation with Authoritative Workbook & RTM:**
  - In the execution workbook (`Cycle2` sheet and `Evidence` sheet), all three test cases **Passed** their application-level and API-level workflow assertions (document upload, suggestion processing, session state saving, and handler authorization).
  - However, direct physical verification on the underlying Azure server (raw filesystem folder inspection via Kudu/SSH and direct MySQL port 3306 queries) could not be executed due to Azure staging network firewall policies.
  - In accordance with QA delivery governance, recorded 'Passed' execution results are kept separate from full physical requirement acceptance. Handler authorization screenshots attached for `TC-CM-220` prove route security, but physical file persistence remains subject to this operational limitation.
- **Preserved Documentation:**
  - `qa/playwright/evidence/technical-evidence-summary.md`
  - `qa/playwright/evidence/tc217-file-inventory-sanitized.md`
  - `qa/playwright/evidence/tc219-database-checkpoints-sanitized.md`
  - `qa/playwright/evidence/tc220-document-association-sanitized.md`
