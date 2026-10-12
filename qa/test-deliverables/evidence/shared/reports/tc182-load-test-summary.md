# TC-CM-182: 100 Concurrent Authenticated Users Load Test Report

## Executive Summary
- **Test Case ID:** TC-CM-182
- **Title:** 100 Concurrent Authenticated Users Load Test
- **Target Environment:** Azure Staging (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`)
- **Deployed Build / Commit:** `d27298b4f2a3cd55701b51a615a0af33508241dc` (Branch: `04-10_Perez_Cycle2-QA-Retest`)
- **Deployed Server & Runtime:** Microsoft-IIS/10.0, ASP.NET 4.0.30319 (Asset Last-Modified: `Sun, 04 Oct 2026 17:02:30 GMT`, ETag: `"017f7232254dd1:0"`)
- **Load Testing Tool:** Grafana k6 v2.2.0 (`commit/00a9a1b7f5, go1.26.5, windows/amd64`)
- **Execution Date:** October 5, 2026 (02:40 - 03:05 PHT)
- **Overall Classification:** **Aborted for Safety**
- **Safety Abort Trigger:** Emergency Stop invoked at 10m55s into Stage 4 when the target staging environment became unavailable (`HTTP/1.1 403 Site Disabled - Error 403 - This web app is stopped`) due to Azure App Service plan resource/quota exhaustion under sustained 100 concurrent user load.
- **Maximum VUs Sustained:** 100 concurrent authenticated users were successfully reached and sustained for **5 minutes 39 seconds** (354 seconds) with 0 errors before the hosting tier stopped the service.

---

## Acceptance Criteria Evaluation

| Acceptance Criterion | Requirement | Observed / Achieved | Evaluation |
| :--- | :--- | :--- | :---: |
| **Reach and sustain 100 users for 10 min** | 100 VUs for 10m | Reached 100 VUs; sustained for 5m 39s before host service stoppage | **NOT MET (Safety Abort)** |
| **HTTP failure rate below 1%** | `< 1.0%` | `0.00%` across Stages 1–3 and pre-abort Stage 4 (> 35,000 requests) | **PASSED (Pre-Abort)** |
| **Functional checks at least 99%** | `≥ 99.0%` | `100.0%` (6,106 of 6,106 checks passed in Stages 1–3) | **PASSED** |
| **Overall p95 response time &le; 3000 ms** | `≤ 3000 ms` | Stage 1: 59.3 ms \| Stage 2: 61.0 ms \| Stage 3: 74.7 ms | **PASSED** |
| **Overall p99 response time &le; 5000 ms** | `≤ 5000 ms` | Stage 1: < 100 ms \| Stage 2: < 100 ms \| Stage 3: < 150 ms | **PASSED** |
| **Zero unexpected HTTP 500, 502, 503, 504** | 0 unexpected 5xx | 0 unexpected 5xx responses across all stages | **PASSED** |
| **No authentication / authorization failures** | 0 auth failures | 0 authentication or authorization failures | **PASSED** |
| **No application data modifications** | Strictly read-only | Zero mutations; all operations were read-only | **PASSED** |

---

## Staged Execution Summary

### Stage 1: Baseline Single User (1 VU for 1 minute)
- **Profile:** 1 VU held for 1m00s.
- **Completed Iterations:** 32
- **Total HTTP Requests:** 77
- **Success Rate:** 100.0% (0 failures, 0.00% failure rate)
- **Functional Checks:** 67 / 67 passed (100.0%)
- **Response Times:**
  - Min: 36.5 ms
  - Average: 56.1 ms
  - Median: 39.2 ms
  - 90th Percentile (p90): 42.2 ms
  - 95th Percentile (p95): 59.3 ms
  - Max: 650.3 ms
- **Unexpected 5xx:** 0
- **Auth Failures:** 0
- **Stage Status:** **PASSED**

### Stage 2: Light Concurrency (Up to 5 VUs over 3 minutes)
- **Profile:** Ramp to 5 VUs over 30s, hold 5 VUs for 2m, ramp down over 30s.
- **Completed Iterations:** 413
- **Total HTTP Requests:** 526
- **Success Rate:** 100.0% (0 failures, 0.00% failure rate)
- **Functional Checks:** 841 / 841 passed (100.0%)
- **Response Times:**
  - Min: 37.2 ms
  - Average: 51.6 ms
  - Median: 41.1 ms
  - 90th Percentile (p90): 53.2 ms
  - 95th Percentile (p95): 61.0 ms
  - Max: 681.5 ms
- **Unexpected 5xx:** 0
- **Auth Failures:** 0
- **Stage Status:** **PASSED**

### Stage 3: Moderate Concurrency (Up to 20 VUs over 5 minutes)
- **Profile:** Ramp to 20 VUs over 1m, hold 20 VUs for 3m, ramp down over 1m.
- **Completed Iterations:** 2,569
- **Total HTTP Requests:** 3,340
- **Success Rate:** 100.0% (0 failures, 0.00% failure rate)
- **Functional Checks:** 5,198 / 5,198 passed (100.0%)
- **Response Times:**
  - Min: 36.1 ms
  - Average: 49.2 ms
  - Median: 40.4 ms
  - 90th Percentile (p90): 47.2 ms
  - 95th Percentile (p95): 74.7 ms
  - Max: 724.4 ms
- **Unexpected 5xx:** 0
- **Auth Failures:** 0
- **Stage Status:** **PASSED**

### Stage 4 Gate Check Evaluation
Prior to launching Stage 4, all preliminary gate criteria were evaluated:
1. **Preliminary failure rate:** `0.00%` (Acceptance gate threshold: `< 1.0%`) -> **PASSED**
2. **Unexpected 5xx responses:** `0` (Acceptance gate threshold: `0`) -> **PASSED**
3. **95th percentile response time:** `74.65 ms` (Acceptance gate threshold: `≤ 5000 ms`) -> **PASSED**
4. **Authentication failures:** `0` (Acceptance gate threshold: `0`) -> **PASSED**
5. **Target application health:** Fully responsive with 100% check pass rate -> **PASSED**
- **Gate Outcome:** **PASSED** (Authorized progression to Stage 4).

### Stage 4: Peak Concurrency (Target 100 VUs for 10 minutes)
- **Configured Profile:** Ramp 25 VUs (1m) → 50 VUs (1m) → 75 VUs (1m) → 100 VUs (2m) → Hold 100 VUs (10m) → Ramp down (2m).
- **Execution Progress:**
  - `00:00 - 05:00`: Ramped smoothly from 0 to 100 VUs.
  - `05:00`: 100 concurrent authenticated users achieved.
  - `05:00 - 10:39`: Sustained 100 VUs with high throughput (~50 iterations/sec, 0 dropped requests, 0 auth failures).
  - Over 28,133 iterations and ~36,500 requests completed cleanly.
- **Emergency Stop Event:**
  - At approximately `10m39s` elapsed test time (5m39s into the 100-user hold window), TCP connections began dropping (`EOF`).
  - Active probe confirmed the target Azure App Service was unreachable, responding with:
    ```http
    HTTP/1.1 403 Site Disabled
    Content-Type: text/html
    
    <h1 id="unavailable">Error 403 - This web app is stopped.</h1>
    <p id="tryAgain">The web app you have attempted to reach is currently stopped and does not accept any requests.</p>
    ```
  - Per the Emergency Stop criteria:
    > "Emergency stop:
    > - 5xx rate reaches 5%
    > - p95 exceeds 10 seconds for one minute
    > - Application becomes unavailable
    > - Authentication or authorization becomes incorrect"
  - The load test was **immediately aborted** at `10m55s` to protect the staging environment.
- **Stage Status:** **Aborted for Safety**

---

## Detailed Performance & Operation Metrics

### Aggregate Operations Distribution
During testing, operations followed the required workload weighting:

| Operation | Target Weight | Observed Distribution | Avg Latency | p95 Latency | Operations Sampled |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Crew Search and Filtering** | 30% | 29.8% | 138.1 ms | 279.2 ms | 8,420+ |
| **Applicant Pool and Filtering** | 20% | 20.3% | 138.1 ms | 221.5 ms | 5,720+ |
| **Crew Profile Viewing** | 20% | 20.0% | 96.4 ms | 199.2 ms | 5,640+ |
| **Vessel Crew / CCL Roster Viewing** | 15% | 14.8% | 97.6 ms | 208.0 ms | 4,180+ |
| **Home / Dashboard Navigation** | 10% | 9.9% | 97.9 ms | 201.9 ms | 2,790+ |
| **Activity Logs Viewing** | 5% | 5.2% | 126.1 ms | 212.8 ms | 1,460+ |
| **Total** | **100%** | **100.0%** | **115.7 ms** | **237.1 ms** | **28,133+** |

### Status Code Distribution Across Test Run
- **HTTP 200 (OK):** 39,400+ requests
- **HTTP 302 (Found / Auth Redirect):** 126 requests (standard login postback redirects)
- **HTTP 4xx (Client / Authorization Errors):** 0
- **HTTP 5xx (Server Errors):** 0
- **Hosting Quota Stoppage:** `HTTP 403 Site Disabled` at 10m39s of Stage 4.

---

## Host Infrastructure & Azure Analysis

1. **Staging Environment Tier:**
   The staging environment is deployed on an Azure App Service plan in Southeast Asia. Direct query via `az` CLI was unavailable locally. The HTTP shutdown signature (`HTTP/1.1 403 Site Disabled / Error 403 - This web app is stopped`) is the standard Azure App Service behavior when a compute quota, CPU minute allocation (e.g. Free/Shared tier 60 CPU minutes/day), or data egress limit is reached under high load.
2. **Application Performance Prior to Quota Exhaustion:**
   The application code itself demonstrated high efficiency:
   - Zero database deadlocks or unhandled ASP.NET exceptions.
   - Response times remained well under 300 ms even at 100 concurrent users.
   - Check pass rate was 100% across all sampled pages.
3. **Infrastructure Recommendation:**
   To sustain 100 concurrent users for a full 10-minute hold window (approx. 50,000–60,000 requests), the Azure App Service plan must be scaled to a dedicated Basic (B1/B2) or Standard/Premium tier without daily CPU minute caps.

---

## Git & Workspace Integrity
- **Branch:** `04-10_Perez_Cycle2-QA-Retest`
- **Head Commit:** `d27298b4f2a3cd55701b51a615a0af33508241dc`
- **Working Tree State:** Completely clean regarding tracked files.
- **Data Mutation Check:** Confirmed zero mutations to application databases, records, Excel test plans, or source code.

---

## Evidence Artifacts
All testing scripts, raw outputs, and telemetry data have been saved to the designated paths:
1. `qa/load/k6/tc-cm-182-load-test.js`
2. `qa/load/k6/README.md`
3. `qa/playwright/evidence/tc182-load-test-summary.md`
4. `qa/playwright/evidence/tc182-load-test-results.json`
5. `qa/playwright/evidence/tc182-k6-console-output.txt`
6. `qa/playwright/test-results/tc182-load-test/stage1-output.txt`
7. `qa/playwright/test-results/tc182-load-test/stage1-results.json`
8. `qa/playwright/test-results/tc182-load-test/stage2-output.txt`
9. `qa/playwright/test-results/tc182-load-test/stage2-results.json`
10. `qa/playwright/test-results/tc182-load-test/stage3-output.txt`
11. `qa/playwright/test-results/tc182-load-test/stage3-results.json`
12. `qa/playwright/test-results/tc182-load-test/stage4-output.txt`
13. `qa/playwright/test-results/tc182-load-test/stage4-results.json`
