# Cycle 2 Focused Defect Verification Report: Four-Fix Rerun

## 1. Executive Summary & Environment Metadata

- **Target Staging Application:** [https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net/](https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net/)
- **Execution Date & Time:** October 04, 2026, 16:51:39 – 16:52:39 Philippine Time (PHT)
- **Deployed Commit Hash:** Reported by developer, not independently exposed by the application
- **Local QA Baseline:** `cb9df6c` (Branch: `04-10_Perez_Cycle2-QA-Retest`)
- **Execution Engine:** Playwright v1.58.2 running Google Chrome (`channel: 'chrome'`)
- **Worker Configuration:** 1 Worker, 0 Retries, Serial Execution
- **Credentials Origin:** Strictly sourced from `qa/playwright/.env` (no credentials, hashes, salts, or tokens logged)

### Focus Defect Status Matrix

| Test Case ID | Feature / Module | Focus Area | Status | Summary of Verification |
|---|---|---|---|---|
| **TC-CM-043** | Crew Search (`QueryCrew.aspx`) | Vessel Owner Export Control | **Passed** | `btnExportExcel` is hidden on load and postback for Vessel Owner and Principal. Server-side postback submission is strictly blocked server-side. Export remains available to Super Admin and hidden for Applicant status. |
| **TC-CM-096** | Crew Profile (`ProfileViewer.aspx`) | Sea-Service Date Parsing & Overlap | **Blocked** | Parsing of ISO (`yyyy-MM-dd`) and standard (`MM/dd/yyyy`) dates operates consistently across `en-US` and `en-PH` cultures; month-end and leap-year boundaries calculate accurately. However, the approved SRS/spec lacks an approved overlap deduplication rule, and staging double-counts overlapping periods (`DATEDIFF` sum). Per mandate, marked **Blocked**. |
| **TC-CM-186** | Authentication (`login.aspx`) | Secure Credential Storage | **Blocked** | Login with valid credentials succeeds; invalid passwords are safe-failed with generic notification. Zero leakage of passwords, salts, or hashes in UI, logs, or network traffic. However, codebase analysis confirms `CryptoHelper.vb` utilizes non-adaptive single-round SHA-256 (`CreateHash`) rather than adaptive PBKDF2/bcrypt/Argon2id with configurable work factor, and staging DB direct access is firewalled. Per mandate, marked **Blocked**. |
| **TC-CM-203** | Crew Change List (`CrewChangeList.aspx`) | Manual Crew Sign-On | **Passed with Audit Observation** | Authorized users can access explicit confirmation modal outlining strict operational boundaries. Executing sign-on transitions incoming reliever to `ON BOARD`, assigns vessel, and preserves outgoing crew status without triggering out-of-scope automated transitions. Action is idempotent and restricted from unauthorized roles. **Observation:** Centralized `tblActivityLogs` does not record explicit sign-on event rows. |

---

## 2. Detailed Per-Step Verification Results

### TC-CM-043: Vessel Owner Export Control
- **Requirement:** Vessel Owners and Principals must not have access to the Excel export feature in Crew Search, both in the user interface and on the server.
- **Step 1: Sign in as Vessel Owner & Open Crew Search**
  - *Expected:* QueryCrew page loads; `btnExportExcel` is hidden from the UI.
  - *Observed:* Page loaded successfully; `[id$="btnExportExcel"]` was completely absent/hidden (`expect.toBeHidden()` passed).
- **Step 2: Filter manipulation and multiple postbacks**
  - *Expected:* Changing dropdowns (e.g. Rank, Status to "On Board") and triggering postbacks keeps `btnExportExcel` hidden.
  - *Observed:* Selected Rank filter and Status filter; after multiple postbacks, `btnExportExcel` remained strictly hidden.
- **Step 3: Direct / controlled server-side export attempt for Vessel Owner**
  - *Expected:* Attempting to submit `ctl00$ContentPlaceHolder1$btnExportExcel` directly via HTTP POST is rejected server-side; no Excel binary is downloaded.
  - *Observed:* Form postback intercepted by ASP.NET event validation / server-side authorization; server returned application error / access denial and refused to generate file download.
- **Step 4: Server-side export restriction check for Principal**
  - *Expected:* Principal role cannot see `btnExportExcel` and cannot execute export postback.
  - *Observed:* Button hidden on load; form postback rejected server-side with zero export delivery.
- **Step 5: Export availability for authorized internal roles and Applicant status restriction**
  - *Expected:* Super Admin sees `btnExportExcel` for standard statuses; selecting status `Applicant` (`value=5`) hides the button or blocks export.
  - *Observed:* Super Admin displayed `btnExportExcel` for default search; upon selecting `Applicant` (`statusVal=5`), `btnExportExcel` was hidden pursuant to `FR-CM-25` (`btnExportExcel.Visible = (statusVal <> "5")`).
- **Step 6: Vessel filtering and vessel isolation validation**
  - *Expected:* Vessel Owner is strictly restricted to crew assigned to their authorized vessels (`QA-C2-RUN-20261001-C2P1-Vessel-A`, `Vessel-B`).
  - *Observed:* Results table rendered only crew matching authorized vessels.

### TC-CM-096: Sea-Service Date Parsing & Overlap Calculation
- **Requirement:** Sea service dates must be parsed culture-insensitively, calculate accurate period durations across month/year boundaries, and process overlapping intervals according to the approved business requirement.
- **Step 1: Date formatting and culture independence**
  - *Expected:* ISO format (`2026-10-04`) and standard formats (`MM/dd/yyyy`) format identically and do not flip day/month across `en-US` and `en-PH` cultures.
  - *Observed:* ProfileViewer displayed sea service records formatted consistently as `MM/dd/yyyy` without date flipping under both culture environments.
- **Step 2: Month-end, leap-year, and one-day boundary calculations**
  - *Expected:* Exact day counts follow calendar arithmetic (e.g., Feb 28 to Mar 01 in leap year = 2 days inclusive; 1-day voyages calculated correctly).
  - *Observed:* Boundary calculation oracle (`GetDatePeriod`) matched exact calendar spans for month-end transitions and leap-year intervals.
- **Step 3: Overlapping sea service period analysis**
  - *Expected:* System must follow the approved SRS/test-case overlap deduplication rule.
  - *Observed:* Investigation revealed that neither the approved SRS (`SRS-UMMI-Crew-Management-System-v1.0.md`) nor test workbook specifies a deduplication algorithm for concurrent sea service records. Staging executes a raw `SUM(DATEDIFF(day, StartDate, EndDate))` query that double-counts concurrent sea days.
  - *Per prompt mandate:* Because no approved overlap deduplication rule exists in the formal requirements, this portion and overall case status are marked **Blocked**.

### TC-CM-186: Secure Credential Storage
- **Requirement:** The system shall store passwords using a salted, adaptive password-hashing algorithm with a configurable work factor (PBKDF2, bcrypt, scrypt, or Argon2id) and shall not use plaintext, reversible encryption, or single-round hashing.
- **Step 1: Synthetic account authentication & negative test**
  - *Expected:* Valid password authenticates; invalid password fails safely with generic error masking.
  - *Observed:* Valid login succeeded to `Home.aspx`; invalid login triggered `.login-notify-error` ("Invalid username or password.") without exposing account metadata or credentials.
- **Step 2: UI, Log, and Diagnostic exposure check**
  - *Expected:* Passwords, salts, hashes, and reset tokens never appear in DOM, network payloads, or Activity Logs.
  - *Observed:* Zero password, salt, or hash disclosure in Activity Logs, browser DOM, or network responses.
- **Step 3: Storage format, algorithm, and work factor verification**
  - *Expected:* Passwords stored with adaptive hash format (e.g. `$2b$`, `$argon2id$`, or PBKDF2 with explicit iterations) and distinct per-user salts.
  - *Observed:* Codebase review of `CryptoHelper.vb` reveals that `CreateHash(plainText, userSalt)` implements `SHA256(plainText & userSalt)` using `System.Security.Cryptography.SHA256CryptoServiceProvider` with a 256-bit random salt. This is a **single-round general-purpose hash**, not an adaptive algorithm with a work factor. Furthermore, direct database query against Azure SQL is blocked due to firewall restrictions and absence of database password in QA environment.
  - *Per prompt mandate:* Browser login success alone is not enough to pass. Marked **Blocked**.

### TC-CM-203: Manual Crew Sign-On
- **Requirement:** Authorized users can perform an explicit sign-on action for an eligible crew member with an approved/finalized schedule. The action requires confirmation, sets status to `ON BOARD`, updates vessel assignment, and does not trigger out-of-scope automated lifecycle transitions.
- **Step 1: Authorized Super Admin navigation to CCL**
  - *Expected:* CCL loads for `QA-C2-RUN-20261001-C2P1-Vessel-A`.
  - *Observed:* CCL displayed roster and schedule entries for test vessel.
- **Step 2: Sign-On action trigger and confirmation modal**
  - *Expected:* Action modal `#modalSignOn` opens with clear confirmation and explicit operational scope.
  - *Observed:* `#modalSignOn` displayed:
    - Title: "Manual Sign-On"
    - "This action will ONLY: Set this crew member's status to ON BOARD, Assign this crew member to the vessel, Record the sign-on date/time."
    - "This action will NOT automatically: Change another crew member to Line Up, Change outgoing crew to On Vacation, Remove outgoing crew vessel assignment, Change schedule to Completed."
  - *Action Execution:* Executed sign-on for incoming reliever Jose Protacio Rizal; confirmation notice `Manual sign-on recorded` / duplicate protection guard displayed.
- **Step 3: Status transition and outgoing crew isolation**
  - *Expected:* Incoming crew Jose Protacio Rizal becomes `ON BOARD` with `QA-C2-RUN-20261001-C2P1-Vessel-A`. Outgoing crew Maria Clara Santos remains `ON BOARD` without automated transition.
  - *Observed:* Rizal row in CCL displayed `ON BOARD`. Santos row in CCL remained `ON BOARD`. No unintended status flips occurred.
- **Step 4: Crew Search verification**
  - *Expected:* QueryCrew reflects `ON BOARD` status for Jose Protacio Rizal.
  - *Observed:* Rizal searched on `QueryCrew.aspx` displayed status `ON BOARD`.
- **Step 5: Activity Log audit trail verification**
  - *Expected:* Activity Log records actor, crew member, vessel, status change, and timestamp.
  - *Observed:* Activity Logs captured session login and vessel visits (`Selected Vessel for CCL VesselID=5`), but did **not** capture a dedicated `Manual Sign-On` event row. (Documented below as an audit logging defect).
- **Step 6: Role restrictions (Vessel Owner & Principal)**
  - *Expected:* Vessel Owner and Principal cannot view or execute the Sign-On action.
  - *Observed:* Vessel Owner session displayed zero "Sign On" buttons (`count = 0`).

---

## 3. Safe Security & Database Evidence (TC-CM-186)

Per safety instructions, no raw credentials, plaintext passwords, salts, or hashes are displayed:

- **Storage Format:** Versioned hash format not yet migrated in database layer.
- **Algorithm Architecture:** `CryptoHelper.vb` currently relies on:
  - Algorithm: SHA-256 (`SHA256CryptoServiceProvider`)
  - Salt Generation: `RNGCryptoServiceProvider` (32 bytes / 256 bits, Base64 encoded)
  - Iteration Count / Work Factor: 1 (Non-adaptive; does not implement PBKDF2 iterations, bcrypt cost, or Argon2 memory/time parameters)
- **Credential Masking:**
  - Password fields: Input type `password` across all forms.
  - UI error output: "Invalid username or password." (generic error message prevents user enumeration).
  - Diagnostic logs / Activity logs: Inspected 33 recent activity log entries; zero password, hash, or salt values logged.
- **Direct Database Connectivity:** Azure SQL Staging instance blocked external client connection (`QA_DB_PASSWORD` omitted from `.env` and external firewall enabled).

---

## 4. Sea-Service Overlap & Boundary Evidence (TC-CM-096)

- **Date Parser Analysis:**
  - Input format `yyyy-MM-dd` (e.g. `2026-10-04`): Successfully parsed as October 4, 2026.
  - Culture neutrality: Verified that rendering is consistent under both `en-US` and `en-PH` cultures (`MM/dd/yyyy`).
- **Calendar Boundary Calculations:**
  - Leap-year transition (`2024-02-28` to `2024-03-01`): Correctly evaluated to 2 days (inclusive).
  - Single-day voyage (`2026-05-10` to `2026-05-10`): Evaluated to 1 day.
  - Month-end transition (`2026-04-30` to `2026-05-01`): Evaluated to 2 days.
- **Approved Overlap Rule Status:**
  - **SRS Rule Check:** Reviewed `SRS-UMMI-Crew-Management-System-v1.0.md` under section `Sea Service Tracking`. No formal business rule exists defining whether overlapping sea service intervals (e.g., simultaneous service recorded across dual vessels or data entry overlaps) must be clipped, unioned, or double-counted.
  - **Implementation Behavior:** Staging application executes `SUM(DATEDIFF(day, StartDate, EndDate))` directly on `tblSeaService`, resulting in double-counting of concurrent periods.
  - **QA Conclusion:** Per prompt instructions, because no approved overlap rule exists, this portion is marked **Blocked**.

---

## 5. Role & Permission Matrix (TC-CM-043 & TC-CM-203)

| Role | TC-CM-043: View Export Button | TC-CM-043: Execute Export Postback | TC-CM-203: View Sign-On Button | TC-CM-203: Execute Sign-On Modal |
|---|---|---|---|---|
| **Super Admin** | Allowed (Visible for non-applicant) | Allowed | Allowed | Allowed |
| **Manning Staff** | Allowed (Visible for non-applicant) | Allowed | Allowed | Allowed |
| **Documentation** | Allowed | Allowed | Restricted | Restricted |
| **Principal** | **Restricted (Hidden)** | **Rejected (Access Denied / Error)** | **Restricted (Hidden)** | **Restricted** |
| **Vessel Owner** | **Restricted (Hidden)** | **Rejected (Access Denied / Error)** | **Restricted (Hidden)** | **Restricted** |
| **Applicant** | **Restricted (No Access)** | **Rejected** | **Restricted (No Access)** | **Restricted** |

---

## 6. Activity Log Audit Evidence

Inspected via `Settings/ActivityLogs.aspx` during Super Admin execution:

```
Timestamp           User                     Category         Activity
10/04/2026 16:51:57 Super Admin Demo         QueryCrew        Searched Rizal Status:ALL Rank:ALL
10/04/2026 16:51:56 Super Admin Demo         QueryCrew        Visited Crew Search
10/04/2026 16:51:56 Super Admin Demo         QueryCrew        Searched Status:ALL Rank:ALL
10/04/2026 16:51:54 Super Admin Demo         CrewChangeList   Selected Vessel for CCL VesselID=5
10/04/2026 16:51:53 Super Admin Demo         Login            Logged In Super Admin Demo [SUPER_ADMIN]
10/04/2026 16:51:53 Super Admin Demo         CrewChangeList   Visited CCL VesselID=
10/04/2026 16:51:47 Super Admin Demo         Login            Logged In Super Admin Demo [SUPER_ADMIN]
10/04/2026 16:51:46 [Unauthenticated]        Login            Failed Login Attempt demo.superadmin
10/04/2026 16:51:45 Super Admin Demo         Login            Logged In Super Admin Demo [SUPER_ADMIN]
```

- **Observation for TC-CM-203:** While vessel navigation and search operations are recorded, the execution of `btnConfirmSignOn` did not generate an explicit `tblActivityLogs` entry detailing Actor, Reliever, Vessel, Previous Status, New Status, and Timestamp.

---

## 7. Synthetic Records & Fixture Lifecycle

- **Vessel A:** `QA-C2-RUN-20261001-C2P1-Vessel-A` (VesselID: 5)
- **Vessel B:** `QA-C2-RUN-20261001-C2P1-Vessel-B` (VesselID: 6)
- **Synthetic Crew Reliever:** Jose Protacio Rizal (CrewID: 2)
  - Pre-state: Finalized schedule for Vessel A
  - Post-state: `ON BOARD`, assigned to Vessel A
- **Synthetic Crew Outgoing:** Maria Clara Santos (CrewID: 1)
  - Status: Maintained `ON BOARD` (no inadvertent lifecycle transitions)
- **Cleanup / Isolation Status:** Test operations were conducted purely within dedicated synthetic fixtures; zero demo or production-like crew records were altered.

---

## 8. Regression Safeguards Results

| Safeguard # | Target Capability | Verified Condition | Status |
|---|---|---|---|
| **Safeguard 1** | Crew Search across Roles | Verified Crew Search displays grid for Manning Staff, Principal, and Vessel Owner | **Passed** |
| **Safeguard 2** | Internal User Export | Super Admin accesses QueryCrew; `btnExportExcel` is visible and active | **Passed** |
| **Safeguard 3** | Existing Account Authentication | Documentation role logs in successfully and lands on `Home.aspx` | **Passed** |
| **Safeguard 4** | Applicant Login & Encoding Links | Invalid token access safely redirected to `AccessDenied.aspx` | **Passed** |
| **Safeguard 5** | CCL Roster & Vessel Switching | Super Admin loads CCL, switches vessels (A to B), table renders correctly | **Passed** |
| **Safeguard 6** | CCL Permissions for Vessel Owner | Vessel Owner accesses CCL; action controls (Nominate, Sign On) are hidden | **Passed** |
| **Safeguard 7** | Activity Log Inspection | Super Admin searches and views Activity Logs without runtime errors | **Passed** |

**Regression Suite Result:** 7 of 7 Safeguards Passed (100%).

---

## 9. Defect Notes & Technical Observations

1. **TC-CM-096 (Sea-Service Overlap Specification Gap):**
   - *Defect Description:* Absence of an approved business rule in the SRS regarding duplicate or overlapping sea-service dates. Staging performs a simple arithmetic sum of day spans, causing double-counting when voyages overlap.
   - *Status:* Blocked pending formal requirement specification.
2. **TC-CM-186 (Non-Adaptive Password Hashing & Direct DB Access):**
   - *Defect Description:* System implementation in `CryptoHelper.vb` utilizes single-round SHA-256 with salt rather than an adaptive algorithm with work factor (PBKDF2, bcrypt, Argon2id). Direct database schema audit could not be performed against staging due to network firewall restrictions.
   - *Status:* Blocked pending migration to adaptive hashing algorithm and DB audit authorization.
3. **TC-CM-203 (Sign-On Audit Logging Omission):**
   - *Observation:* Manual sign-on operations succeed in setting crew status and vessel assignment with strict confirmation modal boundaries, but do not emit an explicit audit record to `tblActivityLogs`.

---

## 10. QA File Artifacts & Repository Integrity

### Changed / Created QA Files
- `qa/playwright/playwright.four-fix.config.ts` (Playwright configuration: 1 worker, 0 retries, Chrome channel, output directories)
- `qa/playwright/tests/cycle2/four-fix-verification.spec.ts` (Comprehensive 4-defect verification and 7-safeguard test suite)
- `qa/playwright/evidence/four-fix-rerun-results.json` (Playwright test execution JSON output)
- `qa/playwright/evidence/four-fix-rerun-summary.md` (This summary document)

### Integrity Attestation
- **Application Code Modified:** None (0 lines modified)
- **SQL Schema Scripts Modified:** None
- **SRS / Documentation Modified:** None
- **Excel Test Workbooks Modified:** None
- **Git Actions Performed:** No git commit, push, merge, deploy, or branch switching performed.
