# UMMI Playwright Test Suite — Phase 2 Execution Summary

> **Environment:** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`  
> **Browser:** Google Chrome (`channel: 'chrome'`)  
> **Workers:** 1 | **Retries:** 0 | **Execution Mode:** Controlled Order  
> **Date:** October 01, 2026  
> **Synthetic Run Identifier:** `QA-C2-RUN-20261001-C2P1`  
> **Test File:** `qa/playwright/tests/cycle2/phase2.spec.ts`  
> **Evidence Artifacts:**
> - HTML Report: `qa/playwright/playwright-report/index.html`
> - JSON Results: `qa/playwright/evidence/results.json`
> - Screenshots & Traces: `qa/playwright/test-results/`

---

## 1. Executive Summary

| Category | Count | Percentage |
| :--- | :---: | :---: |
| **Passed** | **15** | **65.2%** |
| **Failed** | **8** | **34.8%** |
| **Skipped** | **0** | **0.0%** |
| **Blocked** | **0** | **0.0%** |
| **Total Phase 2 Cases** | **23** | **100.0%** |

---

## 2. Phase 2 Test Case Inventory & Execution Results

| # | Test Case ID | Test Case Title | Actor | Operation | Controlled Fixture | Expected Result | Status | Duration | Observed Result & Defect Note |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: | :--- |
| 1 | **TC-CM-140** | Encoding link validation - Reject missing validity | Manning Staff | Read-Only | Manning Staff session / Generate Link modal | Error alert displays; no link generated | `PASSED` | 6.7s | Validation alert displayed; no link generated or persisted. |
| 2 | **TC-CM-144** | Email composition - Compose encoding email without claiming delivery | Manning Staff | Read-Only | Manning Staff session / Send Email modal | Email client opens / composer rendered with applicant email, subject and link; audit log recorded | `FAILED` | 7.5s | **Defect:** Step 1 passed (modal opened with prepopulated body & subject without fake delivery claim). Step 2 failed on audit verification due to `AuditHelper.vb` staging defect (`Unknown column 'timestamp'`). |
| 3 | **TC-CM-163** | Self-encoding - Deny missing link | Unauthenticated Applicant | Read-Only | Direct anonymous navigation to `/Applicant/SelfEncode.aspx` | Redirect to `AccessDenied.aspx` with "Access Denied" notice | `PASSED` | 4.1s | Direct navigation without encrypted link parameter immediately redirected to `AccessDenied.aspx`. |
| 4 | **TC-CM-164** | Self-encoding - Deny unknown link | Unauthenticated Applicant | Read-Only | Tampered AES-256 link token | Redirect to `AccessDenied.aspx`; security audit logged | `FAILED` | 5.3s | **Defect:** Step 1 passed (invalid/tampered ciphertext rejected and redirected to `AccessDenied.aspx`). Step 2 failed because security log failed to insert in database due to `AuditHelper.vb` defect. |
| 5 | **TC-CM-136** | Encoding link - Generate personalized Active link | Manning Staff | Write | Manning Staff account; isolated synthetic link | Valid Active link generated with encrypted payload containing link ID; cleaned up | `PASSED` | 6.2s | Personalized link generated, AES-256 payload verified, verified in Manage Links grid; cleaned up post-test. |
| 6 | **TC-CM-138** | Encoding link validation - Reject missing name | Manning Staff | Read-Only | Manning Staff session / Generate Link modal | Validation alert displayed; generation blocked | `PASSED` | 5.9s | Missing name error banner displayed; no link generated. |
| 7 | **TC-CM-139** | Encoding link validation - Reject missing email | Manning Staff | Read-Only | Manning Staff session / Generate Link modal | Validation alert displayed; generation blocked | `PASSED` | 6.1s | Missing email error banner displayed; no link generated. |
| 8 | **TC-CM-141** | Encoding link validation - Reject malformed email | Manning Staff | Read-Only | Manning Staff session / Generate Link modal | Malformed email rejected; generation blocked | `PASSED` | 5.3s | Regex validation rejected invalid email formats (`invalid-email`, `user@`, `@domain.com`). |
| 9 | **TC-CM-142** | Encoding link validation - Reject invalid calendar date | Manning Staff | Read-Only | Manning Staff session / Generate Link modal | Non-date string rejected; generation blocked | `PASSED` | 6.1s | Malformed date `2026-99-99` rejected with validation warning. |
| 10 | **TC-CM-162** | Self-encoding - Valid Active link opens scoped form | Unauthenticated Applicant | Read-Only | Fresh Active synthetic link | Form opens with prepopulated applicant name, email, and position | `PASSED` | 7.6s | Navigating to valid AES-256 encrypted link successfully loaded Step 1 of `SelfEncode.aspx` with pre-filled name & email. |
| 11 | **TC-CM-165** | Self-encoding - Deny Expired link | Unauthenticated Applicant | Read-Only | Synthetic link with expired validity date | Redirect to `AccessDenied.aspx`; access audit logged | `FAILED` | 5.8s | **Defect:** Step 1 passed (expired validity link redirected to `AccessDenied.aspx`). Step 2 failed on audit log assertion due to `AuditHelper.vb` defect. |
| 12 | **TC-CM-166** | Self-encoding - Deny Used link | Unauthenticated Applicant | Read-Only | Consumed synthetic link (status = 'Used') | Redirect to `AccessDenied.aspx`; access audit logged | `FAILED` | 12.6s | **Defect:** Step 1 passed (consumed link rejected with `AccessDenied.aspx` on subsequent access). Step 2 failed on audit log assertion due to `AuditHelper.vb` defect. |
| 13 | **TC-CM-167** | Self-encoding - Deny Active link with past validity | Unauthenticated Applicant | Read-Only | Active link record with past validity date | Redirect to `AccessDenied.aspx`; access audit logged | `FAILED` | 8.1s | **Defect:** Step 1 passed (past validity active link rejected with `AccessDenied.aspx`). Step 2 failed on audit log assertion due to `AuditHelper.vb` defect. |
| 14 | **TC-CM-168** | Self-encoding - Applicant session cannot browse staff pages | Applicant Session | Read-Only | Active self-encoder session | Unauthorized staff URLs blocked and redirected | `PASSED` | 10.0s | Direct applicant access to `/Applicant/ApplicantPool.aspx`, `/Crew/QueryCrew.aspx`, and `/Settings/ActivityLogs.aspx` redirected to login/home. |
| 15 | **TC-CM-103** | Statutory verification - Verify Benefit numbers | Manning Staff | Write | Crew A001 (`QA Maria Santos`) & AES-256 verifier link | Verifier banner displays; "Verified benefits" success alert; profile reloads with "Benefits Verified" | `FAILED` | 6.7s | **Defect:** Step 1 passed (Verifier banner displayed, verification executed, success alert shown, profile reloaded with "Benefits Verified"). Step 2 failed on audit assertion due to `AuditHelper.vb` defect. |
| 16 | **TC-CM-104** | Statutory verification - Verify TIN | Manning Staff | Write | Crew A001 (`QA Maria Santos`) & AES-256 verifier link | Verifier banner displays; "Verified tin" success alert; profile reloads with "TIN Verified" | `FAILED` | 6.9s | **Defect:** Step 1 passed (Verifier banner displayed, TIN verified, profile reloaded with "TIN Verified"). Step 2 failed on audit assertion due to `AuditHelper.vb` defect. |
| 17 | **TC-CM-132** | Manual applicant - Save valid manual applicant | Manning Staff | Write | Manning Staff account; synthetic applicant payload | Form submits successfully; new applicant visible in Applicant Pool grid | `PASSED` | 6.4s | Multi-step form submitted with TD-APFULL data; re-authenticated Manning Staff verified applicant in `ApplicantPool.aspx` grid; purged post-test. |
| 18 | **TC-CM-133** | Manual applicant - Reject missing and malformed manual data | Manning Staff | Read-Only / Write | Manning Staff account; missing required field payload | Validation error displayed; no record saved; resubmission succeeds | `PASSED` | 9.6s | Step 1 rejected incomplete submission and confirmed 0 rows in pool; Step 2 corrected missing fields and completed submission. |
| 19 | **TC-CM-143** | Encoding link validation - Optional position and default validity | Manning Staff | Write | Manning Staff session / Generate Link modal | Link generated successfully with blank position and default 24h validity | `PASSED` | 5.5s | Verified default validity is populated and optional position allows successful generation; cleaned up. |
| 20 | **TC-CM-160** | Resend link - Resend existing Active link | Manning Staff | Read-Only | Existing Active synthetic link on `gvLinks` | Link record remains Active; mail client or resend dialog opened; audit logged | `FAILED` | 7.3s | **Defect:** Step 1 passed (Resend link clicked, link status confirmed as Active). Step 2 failed on audit log assertion due to `AuditHelper.vb` defect. |
| 21 | **TC-CM-170** | Self-encoding - Submit valid applicant and consume link | Unauthenticated Applicant | Write | Fresh Active synthetic link & full applicant payload | Multi-step form completes; link status transitions to 'Used'; applicant appears in Pool | `PASSED` | 11.6s | Form submitted across 3 wizard steps; link verified 'Used' in database/UI; applicant found in Applicant Pool; purged post-test. |
| 22 | **TC-CM-171** | Self-encoding - Validation retains valid entered data | Unauthenticated Applicant | Read-Only | Fresh Active synthetic link | Server-side validation error displayed; previously entered valid fields preserved | `PASSED` | 14.7s | Missing Step 1 required field triggered server validation; First Name and DOB inputs remained preserved after postback. |
| 23 | **TC-CM-172** | Self-encoding - Repeated or concurrent submission does not duplicate | Unauthenticated Applicant | Write | Fresh Active synthetic link & concurrent sessions | First submit succeeds and marks link 'Used'; second concurrent submit is rejected with Access Denied | `PASSED` | 14.3s | Concurrent submission handled cleanly: Tab 1 succeeded and transitioned link to 'Used'; Tab 2 received Access Denied without duplicate applicant creation. |

---

## 3. Analysis of Critical Staging Defect

### Defect Summary: Broken Activity Logging Across Azure Staging
- **Source File:** `CrewMgmt/App_Code/AuditHelper.vb` (introduced in commit `26d03d7`)
- **SQL Statement:**
  ```sql
  INSERT INTO tbl_activity_log (user_id, activity, fullname, category, ip_address, timestamp) 
  VALUES (@uid, @act, @fn, @cat, @ip, @ts)
  ```
- **Root Cause:** In the production schema (`ummi.sql`), the column name in `tbl_activity_log` is `date_time`, NOT `timestamp`. MySQL immediately rejects the insert with:
  ```
  Unknown column 'timestamp' in 'field list'
  ```
- **Consequence:** Because `AuditHelper.vb` wraps database logging operations in a generic `Try...Catch ex As Exception`, the error fails silently without crashing the user interface. Consequently, **zero activity logs have been recorded on the Azure staging environment since 2026-09-29**.
- **Impact on Phase 2 Tests:** All 8 failed tests (`TC-CM-144`, `TC-CM-164`, `TC-CM-165`, `TC-CM-166`, `TC-CM-167`, `TC-CM-103`, `TC-CM-104`, `TC-CM-160`) passed all of their functional UI and workflow steps, but failed solely because the Excel test plan requires asserting the presence of the audit log in `ActivityLogs.aspx`. In strict compliance with test guidelines ("Do not treat navigation, button visibility, or HTTP 200 alone as proof of success when the test requires a workflow transition"), these tests were accurately marked `FAILED`. Per instructions, application source code was not modified to mask this defect.

---

## 4. Controlled Test Data & Integrity Safeguards

- **Isolation:** All write operations utilized dedicated synthetic link and applicant records with unique timestamp suffixes (`QA-C2-TC132-*`, `QA-C2-TC165-*`, `QA-C2-TC166-*`, `QA-C2-TC170-*`, `QA-C2-TC172-*`).
- **Targeted Teardown:** Every test creating synthetic records cleaned up only its own temporary records upon test completion.
- **Fixture Preservation:** Baseline fixtures from `QA-C2-RUN-20261001-C2P1` (including `A001`, `B001`, `QA Vessel A`, and document fixtures) were left intact and unaltered for subsequent testing phases.
- **Code & Repository Integrity:** No application source code (`.vb`, `.aspx`), SQL scripts, Excel workbooks, or Phase 1 evidence files were modified. No commits, pushes, merges, or deployments were performed.
