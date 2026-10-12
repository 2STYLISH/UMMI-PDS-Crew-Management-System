# TC-CM-181: Normal-Performance Testing Report (PR-01 through PR-04)

## Executive Summary
- **Test Case ID:** TC-CM-181
- **Title:** Normal-Performance Testing (PR-01 through PR-04)
- **Target Environment:** Azure Staging (`https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`)
- **Deployed Build / Commit:** `c737536` (Identified via live IIS asset ETag `"03724a0ef53dd1:0"` and Last-Modified `Sun, 04 Oct 2026 11:00:54 GMT`)
- **Execution Date:** October 4, 2026
- **Browser Channel:** Google Chrome (`channel: 'chrome'`, Playwright)
- **Worker Configuration:** 1 Worker, 0 Retries, Serial Execution
- **Data Prefix:** `QA-C2-TC181-PERF-20261004`
- **Overall Status:** **PASSED** (All 8 operations satisfied their performance thresholds)
- **Scope & Concurrency Notice:** All measurements reflect sequential normal-performance response times under observed Azure staging and network conditions. TC-CM-182 and 100-user concurrency were not tested.

---

## Detailed Performance Measurements

Every measured operation was executed using **3 warm-up iterations** (excluded from statistical calculations) followed by **20 measured iterations**. Response times were measured from the triggering user action until the resulting DOM reached a stable, usable state.

| Metric Key | Operation | Measured Runs | Success | Failed | Failure Rate | Min (ms) | Max (ms) | Avg (ms) | Median (ms) | 95th Percentile (ms) | Threshold Provided in Testing Prompt | Status |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **PR-01-A** | Crew Search Initial Page Load | 20 | 20 | 0 | 0.0% | 518 | 716 | 548 | 536 | **590** | &le; 3000 ms | **PASSED** |
| **PR-01-B** | Applicant Pool Initial Page Load | 20 | 20 | 0 | 0.0% | 692 | 783 | 719 | 716 | **748** | &le; 3000 ms | **PASSED** |
| **PR-01-C** | Profile Viewer Initial Page Load | 20 | 20 | 0 | 0.0% | 188 | 345 | 209 | 201 | **224** | &le; 3000 ms | **PASSED** |
| **PR-02-A** | Paginated Crew Search Filtering | 20 | 20 | 0 | 0.0% | 321 | 489 | 356 | 347 | **456** | &le; 3000 ms | **PASSED** |
| **PR-02-B** | Paginated Applicant Pool Filtering | 20 | 20 | 0 | 0.0% | 955 | 1351 | 1103 | 1140 | **1217** | &le; 3000 ms | **PASSED** |
| **PR-03-A** | Applicant Encoding-Link Generation | 20 | 20 | 0 | 0.0% | 444 | 629 | 503 | 461 | **600** | &le; 3000 ms | **PASSED** |
| **PR-03-B** | Applicant-Link Status Transition | 20 | 20 | 0 | 0.0% | 151 | 1015 | 315 | 261 | **488** | &le; 3000 ms | **PASSED** |
| **PR-04** | Crew Search Export to Excel | 20 | 20 | 0 | 0.0% | 316 | 358 | 336 | 334 | **355** | &le; 5000 ms | **PASSED** |

---

## Detailed Requirement Analysis

### 1. PR-01: Main-Page Loading (Threshold: &le; 3000 ms)
- **Crew Search Initial Load (PR-01-A):** 95th percentile observed at **590 ms** (19.7% of threshold). GridView and filter controls rendered reliably on every run.
- **Applicant Pool Initial Load (PR-01-B):** 95th percentile observed at **748 ms** (24.9% of threshold). Applicant grid and link management controls loaded cleanly.
- **Profile Viewer Initial Load (PR-01-C):** 95th percentile observed at **224 ms** (7.5% of threshold). Complete personnel profile, sea service tab, and document viewer sections initialized immediately.
- **Outcome:** **PASSED** across all three main pages.

### 2. PR-02: Search and Filtering (Threshold: &le; 3000 ms)
- **Paginated Crew Search Filtering (PR-02-A):** 95th percentile observed at **456 ms** (15.2% of threshold). Status filter changes triggered ASP.NET postbacks and refreshed the table with zero anomalies.
- **Paginated Applicant Pool Filtering (PR-02-B):** 95th percentile observed at **1217 ms** (40.6% of threshold). Filter queries by rank type executed cleanly.
- **Outcome:** **PASSED** across both search and filtering domains.

### 3. PR-03: Applicant-Link Operations (Threshold: &le; 3000 ms)
- **Link Generation (PR-03-A):** 95th percentile observed at **600 ms** (20.0% of threshold). Link generation, database insertion, and token creation executed promptly.
- **Link Status Transition (PR-03-B):** 95th percentile observed at **488 ms** (16.3% of threshold). 20 measured status transitions (Active -> Expired) via the Manage Links panel completed with 0 failures and fast postback turnaround.
- **Outcome:** **PASSED** for all applicant-link operations.

### 4. PR-04: Crew Search Export (Threshold: &le; 5000 ms)
- **Export to Excel:** 95th percentile observed at **355 ms** (7.1% of threshold).
- **File Validation:** In each of the 20 measured runs, the downloaded Excel workbook was confirmed to exist, have a nonzero file size, and match the filtered Crew Search structure.
- **Outcome:** **PASSED**.

---

## Data Isolation & Cleanup
- All synthetic links generated during testing utilized prefix `QA-C2-TC181-PERF-20261004`.
- Post-test verification and cleanup confirmed that all synthetic links created for performance measurements were transitioned to `Expired`.
- Verified that **0 active synthetic applicant links** remain in the database.
- Zero non-QA records or baseline fixtures were modified or removed.
