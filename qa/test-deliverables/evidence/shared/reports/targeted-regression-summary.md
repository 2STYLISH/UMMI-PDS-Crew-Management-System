# Cycle 2 Focused Regression Test Summary Report

**Execution Date / Time:** 2026-10-04 15:29:20 PHT  
**Target Environment (Deployed Azure Staging):** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`  
**Git Branch:** `04-10_Perez_Cycle2-QA-Retest`  
**Git Commit Tested:** `cb9df6c` (`fix(ccl): preserve cancelled EOC state in schedule display`)  
**Execution Engine:** Playwright v1.63.0 (Google Chrome channel)  
**Execution Settings:** 1 worker, 0 retries, serial execution (`playwright.targeted-regression.config.ts`)  

---

## 1. Executive Summary & Test Results Matrix

| Metric | Count |
| :--- | :--- |
| **Total Test Cases Retested** | 12 |
| **Passed** | 11 |
| **Failed** | 1 (Legitimate Staging Defect: TC-CM-043) |
| **Skipped** | 0 |
| **Blocked** | 0 |

### Retest Results Table

| Test Case ID | Feature / Area | Expected Result | Observed Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TC-CM-043** | Crew Query / Vessel Owner Visibility & Export Control | Vessel Owner sign-in hides `btnExportExcel` on initial load and postback; server-side export rejected for Vessel Owner; authorized internal roles retain export access. | Initial load for Vessel Owner resolves `btnExportExcel` as **visible** (`ContentPlaceHolder1_btnExportExcel` rendered in DOM). Role filter postback also retains Export button. Defect in `QueryCrew.aspx.vb` line 343 (`IsPrincipal()` only checks `ROLE_PRINCIPAL`, not `ROLE_VESSEL_OWNER`). | **FAILED** |
| **TC-CM-103** | Profile Viewer / Statutory Benefit Verification | Synthetic benefit numbers verified; status becomes Verified; Activity Log records actor, `ProfileViewer` category, action `Verified benefits`, and timestamp; record restored after verification. | Benefit numbers verified successfully (`btnVerifyBenefits` disabled, label updated). Activity Log entry found with Category: `ProfileViewer`, Action: `Verified benefits for crew ID:...`, Actor: `superadmin`. Reset restored safely. | **PASSED** |
| **TC-CM-104** | Profile Viewer / Statutory TIN Verification | Synthetic TIN verified; status becomes Verified; Activity Log records actor, `ProfileViewer` category, action `Verified tin`, and timestamp; record restored after verification. | TIN verified successfully (`btnVerifyTIN` disabled, label updated). Activity Log entry found with Category: `ProfileViewer`, Action: `Verified tin for crew ID:...`, Actor: `superadmin`. Reset restored safely. | **PASSED** |
| **TC-CM-144** | Applicant Pool / Compose Applicant Link Email | Email composition modal opens with validity date in template body; does not claim email was sent or delivered; Activity Log records `Opened mail client for link email`. | Link generated with tomorrow's validity. Mail composition modal opened; mail client trigger verified without delivery assertion; Activity Log contains Category: `ApplicantPool`, Action: `Opened mail client for link email to tc144-regression@example.com`. Synthetic link cleaned up. | **PASSED** |
| **TC-CM-160** | Applicant Pool / Resend Active Applicant Link | Resend action against active link opens mail client with existing token/validity; link remains Active; Activity Log records `Opened mail client for resend link`. | Resend link clicked on active applicant. Mail client composition opened with active token; status remained `Active`. Activity Log confirmed Category: `ApplicantPool`, Action: `Opened mail client for resend link to tc160-regression@example.com`. Synthetic link cleaned up. | **PASSED** |
| **TC-CM-164** | Self-Encoding / Deny Corrupt / Unknown Token Link | Corrupt/unknown token accessed unauthenticated; denied immediately and routed to `AccessDenied.aspx` without infinite redirect; privacy-safe audit entry logged. | Accessing `/login.aspx?e=INVALID_UNKNOWN_CORRUPT_TOKEN_20261004` routed to `/Applicant/AccessDenied.aspx` (HTTP 200, "Access Denied"). Activity Log records Category: `ApplicantLink`, Action: `Malformed encoding link: ...` without token exposure. | **PASSED** |
| **TC-CM-165** | Self-Encoding / Deny Expired Link | Link generated with expired validity date; unauthenticated access routed to `AccessDenied.aspx`; privacy-safe audit entry logged. | Expired link accessed in clean browser context; immediately redirected to `/Applicant/AccessDenied.aspx`. Activity Log records Category: `ApplicantLink`, Action: `Invalid/expired encoding link attempt (Expired)`. Synthetic link cleaned up. | **PASSED** |
| **TC-CM-166** | Self-Encoding / Deny Used Link | Completed applicant submission consumes token; subsequent access attempt is rejected and routed to `AccessDenied.aspx`; privacy-safe audit entry logged. | First submission successfully saved applicant data and consumed link. Second access to same URL routed to `/Applicant/AccessDenied.aspx`. Activity Log records Category: `ApplicantLink`, Action: `Invalid/expired encoding link attempt (Used)`. Synthetic link cleaned up. | **PASSED** |
| **TC-CM-167** | Self-Encoding / Deny Active Link with Past Validity | Active link whose validity date has elapsed is rejected upon access and routed to `AccessDenied.aspx`; privacy-safe audit entry logged. | Link created with yesterday's validity date. Clean context access routed to `/Applicant/AccessDenied.aspx`. Activity Log records Category: `ApplicantLink`, Action: `Invalid/expired encoding link attempt (Expired by date)`. Synthetic link cleaned up. | **PASSED** |
| **TC-CM-201** | Crew Change List / Cancel Finalized Schedule | Finalized schedule on isolated test vessel cancelled by Super Admin; schedule status transitions to `Cancelled`; associated EOC transitions to `Cancelled` or approved cancelled-EOC state (`Superseded`); "No EOC" rejected; unrelated schedules unaffected; audit log recorded. | Super Admin cancelled schedule on test vessel (`QA-VESSEL-A`). Schedule column updated to `Cancelled`. EOC column displayed approved cancelled state (`Superseded`, rejecting `No EOC`). Unrelated vessel rows unaffected. Activity Log records Category: `CrewChangeList`, Action: `Cancelled CCL Schedule: ScheduleID=...`. | **PASSED** |
| **TC-CM-204** | Crew Change List / CCL Comprehensive Audit Trail | Full CCL lifecycle actions (nomination, schedule creation, finalization, amendment/cancellation) generate structured audit entries with actor, action, affected record, category, and timestamp. | CCL workflow executed on isolated vessel. Activity Log verified with Category: `CrewChangeList`, verifying presence of `Schedule`, `Finalized`, `Amended`, and `Cancelled` actions with valid timestamps, user identity, and affected schedule IDs. | **PASSED** |
| **TC-CM-218** | AI Document Extraction / Privacy-Safe Audit Logs | AI document upload and parsing emit privacy-safe audit logs; raw document bytes, full PII, API keys, CSRF tokens, and credentials omitted; success and failure outcomes distinguished. | Valid document uploaded and extracted; invalid file rejected. Activity Log verified with categories `ApplicantAiExtract` and `ApplicantDocument`. Verified zero exposure of passwords, API keys, AES secrets, or raw payload dumps. Success/failure outcomes logged distinctly. Synthetic link cleaned up. | **PASSED** |

---

## 2. Activity-Log Evidence Summary

Audit trail verification was conducted across all applicable test cases:

1. **Statutory Verifications (TC-CM-103, TC-CM-104):**
   - Category: `ProfileViewer`
   - Actions: `Verified benefits for crew ID: ...`, `Verified tin for crew ID: ...`
   - Verified Actor: `superadmin`
   - Timestamp format: Standard datetime string logged in UTC/PHT.

2. **Applicant Link Mail Operations (TC-CM-144, TC-CM-160):**
   - Category: `ApplicantPool`
   - Actions: `Opened mail client for link email to tc144-regression@example.com`, `Opened mail client for resend link to tc160-regression@example.com`
   - Verified that the system logs opening/composing the email client, rather than claiming successful SMTP delivery.

3. **Link Access Denials (TC-CM-164, TC-CM-165, TC-CM-166, TC-CM-167):**
   - Category: `ApplicantLink`
   - Actions: `Malformed encoding link: ...`, `Invalid/expired encoding link attempt (Expired)`, `Invalid/expired encoding link attempt (Used)`, `Invalid/expired encoding link attempt (Expired by date)`
   - Verified that tokens and sensitive applicant query params are masked/sanitized in the log message.

4. **Crew Change List Operations (TC-CM-201, TC-CM-204):**
   - Category: `CrewChangeList`
   - Actions: `Cancelled CCL Schedule: ScheduleID=...`, `Finalized CCL Schedule`, `Amended CCL Schedule`
   - Verified Actor: `superadmin`

5. **AI Extraction Logging (TC-CM-218):**
   - Categories: `ApplicantAiExtract`, `ApplicantDocument`
   - Verified that no binary document bytes, raw JSON dumps with PII, encrypted tokens, or credential strings appear in the activity description.

---

## 3. Defect Notes (Failures)

### Defect: TC-CM-043 — Export Excel Button Visible to Vessel Owner
- **Component:** `CrewMgmt/Crew/QueryCrew.aspx.vb` (Line 343)
- **Defect Description:**
  In `QueryCrew.aspx.vb`, role-based visibility is applied in `ApplyRoleVisibility()`, which sets `btnExportExcel.Visible = False` for Vessel Owner. However, inside `SearchCrew()`, the code evaluates:
  ```vb
  If Not IsPrincipal() Then
      btnExportExcel.Visible = (dt IsNot Nothing AndAlso dt.Rows.Count > 0)
  End If
  ```
  Because `IsPrincipal()` returns true only when `CurrentRole() = ROLE_PRINCIPAL`, it returns `False` for `ROLE_VESSEL_OWNER`. Consequently, `btnExportExcel.Visible` is set to `True` for Vessel Owners on initial load and postback whenever records are returned.
- **Rule Adherence:** Per testing instructions, assertions were not weakened. The test strictly asserted `toBeHidden()`, and the failure was documented as an active defect in the deployed Azure staging environment.

---

## 4. Synthetic Test Records & Cleanup Verification

All test executions used isolated synthetic records prefixed with `QA-C2-REGRESSION-20261004`:

| Test Case | Synthetic Record Identifier | Creation Purpose | Cleanup Action / Status |
| :--- | :--- | :--- | :--- |
| **TC-CM-103** | Controlled Crew Record (`ID: 154`) | Benefit numbers verification | Controlled statutory flags reset to Unverified; restored safely. |
| **TC-CM-104** | Controlled Crew Record (`ID: 154`) | TIN verification | Controlled statutory flags reset to Unverified; restored safely. |
| **TC-CM-144** | `QA-C2-REGRESSION-20261004-TC144-LinkApp` | Applicant mail link composition | Synthetic link expired and deleted from `ApplicantPool.aspx`. |
| **TC-CM-160** | `QA-C2-REGRESSION-20261004-TC160-ResendApp` | Resend active link | Synthetic link expired and deleted from `ApplicantPool.aspx`. |
| **TC-CM-164** | `INVALID_UNKNOWN_CORRUPT_TOKEN_20261004` | Malformed token test | Transient HTTP request; no database record created. |
| **TC-CM-165** | `QA-C2-REGRESSION-20261004-TC165-ExpApp` | Expired link test | Synthetic link expired and deleted from `ApplicantPool.aspx`. |
| **TC-CM-166** | `QA-C2-REGRESSION-20261004-TC166-UsedApp` | Single-use link test | Synthetic link expired and deleted from `ApplicantPool.aspx`. |
| **TC-CM-167** | `QA-C2-REGRESSION-20261004-TC167-PastApp` | Past-validity link test | Synthetic link expired and deleted from `ApplicantPool.aspx`. |
| **TC-CM-201** | Test Vessel (`QA-VESSEL-A`) / Santos | Finalized schedule cancellation | Reset and restored via CCL workflow without altering production data. |
| **TC-CM-204** | Test Vessel (`QA-VESSEL-A`) / Santos | CCL audit trail verification | Contained within test vessel `QA-VESSEL-A`. |
| **TC-CM-218** | `QA-C2-REGRESSION-20261004-TC218-AiAudit` | AI document extraction | Synthetic link expired and deleted from `ApplicantPool.aspx`. |

---

## 5. QA Artifacts & Verification Checklist

### QA Files Created / Modified
- `qa/playwright/playwright.targeted-regression.config.ts` (Targeted Playwright configuration)
- `qa/playwright/tests/cycle2/targeted-regression.spec.ts` (Targeted 12-test regression specification)
- `qa/playwright/evidence/targeted-regression-results.json` (Playwright JSON test results)
- `qa/playwright/evidence/targeted-regression-summary.md` (This summary document)
- `qa/playwright/targeted-regression-report/` (HTML Playwright report and trace viewer)
- `qa/playwright/test-results/targeted-regression/` (Execution screenshots, error contexts, and traces)

### Strict Constraint Compliance Confirmation
- [x] Tested against deployed Azure staging application (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`), not localhost.
- [x] Executed via Google Chrome with 1 worker, 0 retries, and serial execution.
- [x] Read credentials strictly from `qa/playwright/.env`.
- [x] Zero credentials, passwords, tokens, hashes, salts, CSRF values, or sensitive document contents exposed in reports or logs.
- [x] No modifications made to application source files (`.vb`, `.aspx`, `.cs`).
- [x] No modifications made to the SRS or Excel test workbooks.
- [x] No permanent staging records altered or damaged.
- [x] Zero Git commits, pushes, merges, deployments, or branch switches performed.
- [x] Phase 1, Phase 2, CCL, and AI evidence files preserved untouched.
