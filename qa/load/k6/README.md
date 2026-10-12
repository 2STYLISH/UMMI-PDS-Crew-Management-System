# UMMI PDS - TC-CM-182 Load Testing Suite

## Overview
This directory contains the Grafana k6 load testing suite for **TC-CM-182: 100 Concurrent Authenticated Users Load Test** against the UMMI Crew Management System on Azure Staging (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`).

## Test Architecture & Staging Safeties
- **Protocol:** HTTP/HTTPS WebForms authenticated load testing.
- **Session Isolation:** Per-VU CookieJar maintains independent ASP.NET session state (`ASP.NET_SessionId`, `.ASPXAUTH`, and `ARRAffinity`).
- **Data Protection:** Strictly read-only operations. No links are generated, no documents are uploaded, no crew data is modified, no batch exports are executed, and no CCL roster actions are submitted.
- **Security Compliance:** Untracked credentials are loaded solely via environment variables from `qa/playwright/.env`. No secrets, tokens, or ViewState payloads are ever committed or echoed to logs.

## Workload Distribution
Simulates realistic production crew manager activity across 6 read-only domains:
1. **Crew Search and Filtering (30%):** View and search crew records with status/rank filtering.
2. **Applicant Pool and Filtering (20%):** View and search applicant pool records.
3. **Crew Profile Viewing (20%):** Inspect full crew profiles dynamically harvested from search results.
4. **Vessel Crew / CCL Roster Viewing (15%):** Monitor vessel rosters and crew change lists.
5. **Home / Dashboard Navigation (10%):** Navigate main landing overview.
6. **Activity Logs Viewing (5%):** Audit trail review by authorized administrator.

## Acceptance Criteria & Thresholds
- **Max VUs:** Reach and sustain 100 concurrent authenticated users for 10 minutes.
- **HTTP Failure Rate:** `< 1.0%` (`http_req_failed`).
- **Functional Checks:** `≥ 99.0%` (`checks`).
- **Response Times:**
  - Overall 95th Percentile (p95): `≤ 3000 ms`
  - Overall 99th Percentile (p99): `≤ 5000 ms`
- **Server Health:** 0 unexpected HTTP 500, 502, 503, or 504 responses (`unexpected_5xx == 0`).
- **Authentication:** 0 authentication or authorization failures (`auth_failures == 0`).
- **Data Integrity:** Zero state mutations.

## Staged Execution Phases
1. **Stage 1 (Baseline / Smoke):** 1 VU for 1 minute.
2. **Stage 2 (Light Concurrency):** Ramp to 5 VUs over 30s, hold for 2m, ramp down over 30s.
3. **Stage 3 (Moderate Concurrency):** Ramp to 20 VUs over 1m, hold for 3m, ramp down over 1m.
4. **Stage 4 Gate Check:** Halt prior to Stage 4 if preliminary failure rate ≥ 1%, any unexpected 5xx occurs, p95 > 5000 ms, auth fails, or the application becomes unhealthy.
5. **Stage 4 (Peak Concurrency & Endurance):** Ramp 25 (1m) → 50 (1m) → 75 (1m) → 100 (2m) → Hold 100 for 10m → Ramp down (2m).

## Execution Instructions

To execute with k6 on Windows:
```powershell
# Set credentials from untracked qa/playwright/.env
$envLines = Get-Content "qa/playwright/.env"
foreach ($line in $envLines) {
    if ($line -match '^\s*UMMI_ADMIN_USER\s*=\s*(.*)$') { $env:LOAD_TEST_USER = $matches[1].Trim() }
    if ($line -match '^\s*UMMI_ADMIN_PASSWORD\s*=\s*(.*)$') { $env:LOAD_TEST_PASS = $matches[1].Trim() }
}

# Run individual stage (e.g. Stage 1)
$env:LOAD_STAGE = "1"
& "C:\Program Files\k6\k6.exe" run qa/load/k6/tc-cm-182-load-test.js
```
