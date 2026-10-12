import { test, expect } from '../../fixtures/auth.fixture';
import fs from 'fs';
import path from 'path';

const PERF_PREFIX = 'QA-C2-TC181-PERF-20261004';

function calculateStats(times: number[]) {
  const n = times.length;
  if (n === 0) return { min: 0, max: 0, avg: 0, median: 0, p95: 0 };
  const sorted = [...times].sort((a, b) => a - b);
  const min = sorted[0];
  const max = sorted[sorted.length - 1];
  const sum = sorted.reduce((acc, v) => acc + v, 0);
  const avg = Math.round(sum / n);
  const median =
    n % 2 === 1
      ? sorted[Math.floor(n / 2)]
      : Math.round((sorted[n / 2 - 1] + sorted[n / 2]) / 2);
  const p95Index = Math.min(sorted.length - 1, Math.ceil(0.95 * n) - 1);
  const p95 = sorted[p95Index];
  return { min, max, avg, median, p95 };
}

function getFutureDateString(days: number): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString().split('T')[0];
}

test.describe('TC-CM-181: Normal-Performance Testing (PR-01 through PR-04)', () => {
  test.setTimeout(600000); // 10 minutes

  test('Execute PR-01, PR-02, PR-03, PR-04 Sequential Performance Measurements', async ({
    loginAsRole,
    page,
  }) => {
    // Authenticate once as Manning Staff
    await loginAsRole('MANNING');
    await page.goto('/Crew/QueryCrew.aspx');
    await expect(page.locator('[id$="btnSearch"]')).toBeVisible({ timeout: 15000 });

    const perfMetrics: Record<string, any> = {};

    // =========================================================================
    // PR-01: Main-Page Loading (Threshold: <= 3000 ms)
    // =========================================================================
    await test.step('PR-01-A: Crew Search Initial Page Load', async () => {
      console.log('Starting PR-01-A: Crew Search...');
      for (let w = 1; w <= 3; w++) {
        await page.goto('/Crew/QueryCrew.aspx');
        await expect(page.locator('[id$="btnSearch"]')).toBeVisible();
      }

      const times: number[] = [];
      let success = 0;
      let failed = 0;
      for (let i = 1; i <= 20; i++) {
        const start = Date.now();
        try {
          await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'load' });
          await expect(page.locator('[id$="btnSearch"]')).toBeVisible({ timeout: 10000 });
          await expect(page.locator('[id$="GridViewQueryCrew"]')).toBeVisible({ timeout: 10000 });
          const elapsed = Date.now() - start;
          times.push(elapsed);
          success++;
        } catch (e) {
          failed++;
        }
      }
      const stats = calculateStats(times);
      perfMetrics['PR-01-CrewSearch'] = {
        operation: 'Crew Search Initial Load',
        thresholdMs: 3000,
        runs: 20,
        success,
        failed,
        failureRate: failed / 20,
        ...stats,
        status: stats.p95 <= 3000 && failed === 0 ? 'PASSED' : 'FAILED',
      };
      console.log('PR-01-CrewSearch:', perfMetrics['PR-01-CrewSearch']);
    });

    await test.step('PR-01-B: Applicant Pool Initial Page Load', async () => {
      console.log('Starting PR-01-B: Applicant Pool...');
      for (let w = 1; w <= 3; w++) {
        await page.goto('/Applicant/ApplicantPool.aspx');
        await expect(page.locator('[id$="btnSearch"]')).toBeVisible();
      }

      const times: number[] = [];
      let success = 0;
      let failed = 0;
      for (let i = 1; i <= 20; i++) {
        const start = Date.now();
        try {
          await page.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'load' });
          await expect(page.locator('[id$="btnSearch"]')).toBeVisible({ timeout: 10000 });
          await expect(page.locator('[id$="gvApplicants"]')).toBeVisible({ timeout: 10000 });
          const elapsed = Date.now() - start;
          times.push(elapsed);
          success++;
        } catch (e) {
          failed++;
        }
      }
      const stats = calculateStats(times);
      perfMetrics['PR-01-ApplicantPool'] = {
        operation: 'Applicant Pool Initial Load',
        thresholdMs: 3000,
        runs: 20,
        success,
        failed,
        failureRate: failed / 20,
        ...stats,
        status: stats.p95 <= 3000 && failed === 0 ? 'PASSED' : 'FAILED',
      };
      console.log('PR-01-ApplicantPool:', perfMetrics['PR-01-ApplicantPool']);
    });

    // Obtain stable profile URL
    await page.goto('/Crew/QueryCrew.aspx');
    await expect(page.locator('[id$="btnSearch"]')).toBeVisible();
    const firstProfileLink = page.locator('[id$="GridViewQueryCrew"] tr td a[href*="ProfileViewer"]').first();
    const profileHref = (await firstProfileLink.getAttribute('href')) || '/Crew/ProfileViewer.aspx';
    const profileUrl = profileHref.startsWith('/') ? profileHref : `/Crew/${profileHref}`;

    await test.step('PR-01-C: Profile Viewer Initial Page Load', async () => {
      console.log('Starting PR-01-C: Profile Viewer on', profileUrl);
      for (let w = 1; w <= 3; w++) {
        await page.goto(profileUrl);
        await expect(page.locator('#tabSeaService, #gvDocUMMI, .card-header-ummi').first()).toBeVisible();
      }

      const times: number[] = [];
      let success = 0;
      let failed = 0;
      for (let i = 1; i <= 20; i++) {
        const start = Date.now();
        try {
          await page.goto(profileUrl, { waitUntil: 'load' });
          await expect(page.locator('#tabSeaService, #gvDocUMMI, .card-header-ummi').first()).toBeVisible({ timeout: 10000 });
          const elapsed = Date.now() - start;
          times.push(elapsed);
          success++;
        } catch (e) {
          failed++;
        }
      }
      const stats = calculateStats(times);
      perfMetrics['PR-01-ProfileViewer'] = {
        operation: 'Profile Viewer Initial Load',
        thresholdMs: 3000,
        runs: 20,
        success,
        failed,
        failureRate: failed / 20,
        ...stats,
        status: stats.p95 <= 3000 && failed === 0 ? 'PASSED' : 'FAILED',
      };
      console.log('PR-01-ProfileViewer:', perfMetrics['PR-01-ProfileViewer']);
    });

    // =========================================================================
    // PR-02: Search and Filtering (Threshold: <= 3000 ms)
    // =========================================================================
    await test.step('PR-02-A: Paginated Crew Search Filtering', async () => {
      console.log('Starting PR-02-A: Crew Search Filtering...');
      await page.goto('/Crew/QueryCrew.aspx');
      await expect(page.locator('[id$="btnSearch"]')).toBeVisible();

      const statusSelect = page.locator('[id$="drpdwnCrewStatus"]');
      const searchBtn = page.locator('[id$="btnSearch"]');

      // 3 Warm-up runs (toggle status)
      for (let w = 1; w <= 3; w++) {
        await statusSelect.selectOption({ index: 1 });
        await Promise.all([
          page.waitForResponse(res => res.url().includes('QueryCrew.aspx') && res.request().method() === 'POST'),
          searchBtn.click(),
        ]);
        await page.waitForLoadState('networkidle').catch(() => {});
      }

      // 20 Measured runs
      const times: number[] = [];
      let success = 0;
      let failed = 0;
      for (let i = 1; i <= 20; i++) {
        const targetIndex = i % 2 === 0 ? 1 : 2;
        await statusSelect.selectOption({ index: targetIndex });
        const start = Date.now();
        try {
          await Promise.all([
            page.waitForResponse(res => res.url().includes('QueryCrew.aspx') && res.request().method() === 'POST'),
            searchBtn.click(),
          ]);
          await expect(page.locator('[id$="GridViewQueryCrew"]')).toBeVisible({ timeout: 10000 });
          const elapsed = Date.now() - start;
          times.push(elapsed);
          success++;
        } catch (e) {
          failed++;
        }
      }
      const stats = calculateStats(times);
      perfMetrics['PR-02-CrewSearchFiltering'] = {
        operation: 'Paginated Crew Search Filtering',
        thresholdMs: 3000,
        runs: 20,
        success,
        failed,
        failureRate: failed / 20,
        ...stats,
        status: stats.p95 <= 3000 && failed === 0 ? 'PASSED' : 'FAILED',
      };
      console.log('PR-02-CrewSearchFiltering:', perfMetrics['PR-02-CrewSearchFiltering']);
    });

    await test.step('PR-02-B: Paginated Applicant Pool Filtering', async () => {
      console.log('Starting PR-02-B: Applicant Pool Filtering...');
      await page.goto('/Applicant/ApplicantPool.aspx');
      await expect(page.locator('[id$="btnSearch"]')).toBeVisible();

      const rankTypeSelect = page.locator('[id$="drpdwnRankType"]');
      const searchBtn = page.locator('[id$="btnSearch"]');

      // 3 Warm-up runs
      for (let w = 1; w <= 3; w++) {
        await rankTypeSelect.selectOption({ index: 1 });
        await Promise.all([
          page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST'),
          searchBtn.click(),
        ]);
        await page.waitForLoadState('networkidle').catch(() => {});
      }

      // 20 Measured runs
      const times: number[] = [];
      let success = 0;
      let failed = 0;
      for (let i = 1; i <= 20; i++) {
        const targetIndex = i % 2 === 0 ? 1 : 0;
        await rankTypeSelect.selectOption({ index: targetIndex });
        const start = Date.now();
        try {
          await Promise.all([
            page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST'),
            searchBtn.click(),
          ]);
          await expect(page.locator('[id$="gvApplicants"]')).toBeVisible({ timeout: 10000 });
          const elapsed = Date.now() - start;
          times.push(elapsed);
          success++;
        } catch (e) {
          failed++;
        }
      }
      const stats = calculateStats(times);
      perfMetrics['PR-02-ApplicantPoolFiltering'] = {
        operation: 'Paginated Applicant Pool Filtering',
        thresholdMs: 3000,
        runs: 20,
        success,
        failed,
        failureRate: failed / 20,
        ...stats,
        status: stats.p95 <= 3000 && failed === 0 ? 'PASSED' : 'FAILED',
      };
      console.log('PR-02-ApplicantPoolFiltering:', perfMetrics['PR-02-ApplicantPoolFiltering']);
    });

    // =========================================================================
    // PR-03: Applicant-Link Operations (Threshold: <= 3000 ms)
    // =========================================================================
    await test.step('PR-03-A: Applicant Encoding-Link Generation', async () => {
      console.log('Starting PR-03-A: Link Generation...');
      await page.goto('/Applicant/ApplicantPool.aspx');
      await expect(page.locator('[id$="btnGenerateLink"]')).toBeVisible();

      // Open panel
      await page.locator('[id$="btnGenerateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});
      await expect(page.locator('[id$="panelGenerateLink"]')).toBeVisible({ timeout: 10000 });

      const nameInput = page.locator('[id$="txtLinkFullname"]');
      const emailInput = page.locator('[id$="txtLinkEmail"]');
      const validityInput = page.locator('[id$="txtLinkValidity"]');
      const createBtn = page.locator('[id$="btnCreateLink"]');
      const linkOutput = page.locator('[id$="txtGeneratedLink"]');
      const validityVal = getFutureDateString(3);

      // 3 Warm-up runs
      for (let w = 1; w <= 3; w++) {
        const warmupName = `${PERF_PREFIX}-Warmup-${w}`;
        await nameInput.fill(warmupName);
        await emailInput.fill(`warmup-${w}@example.com`);
        await validityInput.fill(validityVal);
        await Promise.all([
          page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST'),
          createBtn.click(),
        ]);
        await expect(linkOutput).not.toHaveValue('', { timeout: 10000 });
      }

      // 20 Measured runs
      const times: number[] = [];
      let success = 0;
      let failed = 0;
      for (let i = 1; i <= 20; i++) {
        const appName = `${PERF_PREFIX}-Run-${i}`;
        await nameInput.fill(appName);
        await emailInput.fill(`perf-${i}@example.com`);
        await validityInput.fill(validityVal);

        const start = Date.now();
        try {
          await Promise.all([
            page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST'),
            createBtn.click(),
          ]);
          await expect(linkOutput).not.toHaveValue('', { timeout: 10000 });
          const elapsed = Date.now() - start;
          times.push(elapsed);
          success++;
        } catch (e) {
          failed++;
        }
      }
      const stats = calculateStats(times);
      perfMetrics['PR-03-LinkGeneration'] = {
        operation: 'Applicant Link Generation',
        thresholdMs: 3000,
        runs: 20,
        success,
        failed,
        failureRate: failed / 20,
        ...stats,
        status: stats.p95 <= 3000 && failed === 0 ? 'PASSED' : 'FAILED',
      };
      console.log('PR-03-LinkGeneration:', perfMetrics['PR-03-LinkGeneration']);
    });

    await test.step('PR-03-B: Applicant-Link Status Transition (Active -> Expired)', async () => {
      console.log('Starting PR-03-B: Link Status Transition...');
      await page.goto('/Applicant/ApplicantPool.aspx');
      await expect(page.locator('[id$="btnManageLinks"]')).toBeVisible();

      // Automatically accept all confirm dialogs during status transitions
      page.on('dialog', async d => {
        await d.accept().catch(() => {});
      });

      // Open manage links panel
      await page.locator('[id$="btnManageLinks"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});
      await expect(page.locator('[id$="panelManageLinks"]')).toBeVisible({ timeout: 10000 });

      // 3 Warm-up runs
      for (let w = 1; w <= 3; w++) {
        try {
          const firstActiveRow = page.locator('[id$="gvLinks"] tr').filter({ has: page.locator('select[id$="drpdwnNewStatus"]') }).first();
          if (await firstActiveRow.isVisible({ timeout: 3000 }).catch(() => false)) {
            const ddl = firstActiveRow.locator('select[id$="drpdwnNewStatus"]');
            const applyBtn = firstActiveRow.locator('a[id$="btnUpdateStatus"]');
            await ddl.selectOption('Expired');
            await Promise.all([
              page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST'),
              applyBtn.click(),
            ]);
            await expect(page.locator('[id$="lblNotify"], .alert-success')).toBeVisible({ timeout: 10000 });
          }
        } catch (e) {
          console.log('Warmup status transition error:', (e as Error).message);
        }
      }

      // 20 Measured runs
      const times: number[] = [];
      let success = 0;
      let failed = 0;
      for (let i = 1; i <= 20; i++) {
        const start = Date.now();
        try {
          const targetRow = page.locator('[id$="gvLinks"] tr').filter({ has: page.locator('select[id$="drpdwnNewStatus"]') }).first();
          if (!(await targetRow.isVisible({ timeout: 5000 }).catch(() => false))) {
            throw new Error('No row with drpdwnNewStatus visible');
          }

          const ddl = targetRow.locator('select[id$="drpdwnNewStatus"]');
          const applyBtn = targetRow.locator('a[id$="btnUpdateStatus"]');
          await ddl.selectOption('Expired');

          await Promise.all([
            page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST'),
            applyBtn.click(),
          ]);
          await expect(page.locator('[id$="lblNotify"], .alert-success')).toBeVisible({ timeout: 10000 });
          const elapsed = Date.now() - start;
          times.push(elapsed);
          success++;
        } catch (e) {
          console.log(`PR-03-B run ${i} error:`, (e as Error).message);
          failed++;
        }
      }
      const stats = calculateStats(times);
      perfMetrics['PR-03-LinkStatusTransition'] = {
        operation: 'Applicant Link Status Transition',
        thresholdMs: 3000,
        runs: 20,
        success,
        failed,
        failureRate: failed / 20,
        ...stats,
        status: stats.p95 <= 3000 && failed === 0 ? 'PASSED' : 'FAILED',
      };
      console.log('PR-03-LinkStatusTransition:', perfMetrics['PR-03-LinkStatusTransition']);
    });

    // =========================================================================
    // PR-04: Crew Search Export (Threshold: <= 5000 ms)
    // =========================================================================
    await test.step('PR-04: Crew Search Export to Excel', async () => {
      console.log('Starting PR-04: Crew Search Export...');
      await page.goto('/Crew/QueryCrew.aspx');
      await expect(page.locator('[id$="btnExportExcel"]')).toBeVisible({ timeout: 10000 });

      const exportBtn = page.locator('[id$="btnExportExcel"]');
      const scratchDir = path.resolve(__dirname, '../../scratch');
      if (!fs.existsSync(scratchDir)) {
        fs.mkdirSync(scratchDir, { recursive: true });
      }

      // 3 Warm-up runs
      for (let w = 1; w <= 3; w++) {
        const downloadPromise = page.waitForEvent('download', { timeout: 20000 });
        await exportBtn.click();
        const download = await downloadPromise;
        const tempPath = path.join(scratchDir, `warmup_${w}.xls`);
        await download.saveAs(tempPath);
        if (fs.existsSync(tempPath)) fs.unlinkSync(tempPath);
      }

      // 20 Measured runs
      const times: number[] = [];
      let success = 0;
      let failed = 0;
      for (let i = 1; i <= 20; i++) {
        const start = Date.now();
        try {
          const downloadPromise = page.waitForEvent('download', { timeout: 20000 });
          await exportBtn.click();
          const download = await downloadPromise;
          const tempPath = path.join(scratchDir, `perf_export_${i}.xls`);
          await download.saveAs(tempPath);
          const elapsed = Date.now() - start;

          const fileExists = fs.existsSync(tempPath);
          const statsFs = fileExists ? fs.statSync(tempPath) : null;
          const hasContent = statsFs && statsFs.size > 0;

          if (fileExists) fs.unlinkSync(tempPath);

          if (fileExists && hasContent) {
            times.push(elapsed);
            success++;
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
        }
      }
      const stats = calculateStats(times);
      perfMetrics['PR-04-CrewSearchExport'] = {
        operation: 'Crew Search Export to Excel',
        thresholdMs: 5000,
        runs: 20,
        success,
        failed,
        failureRate: failed / 20,
        ...stats,
        status: stats.p95 <= 5000 && failed === 0 ? 'PASSED' : 'FAILED',
      };
      console.log('PR-04-CrewSearchExport:', perfMetrics['PR-04-CrewSearchExport']);
    });

    // Write JSON output with all metrics
    const resultsFile = path.resolve(__dirname, '../../evidence/tc181-performance-results.json');
    fs.writeFileSync(
      resultsFile,
      JSON.stringify(
        {
          testCase: 'TC-CM-181',
          executionDate: new Date().toISOString(),
          targetUrl: 'https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net',
          deployedCommitTested: 'c737536',
          dataPrefix: PERF_PREFIX,
          metrics: perfMetrics,
          overallStatus: Object.values(perfMetrics).every(m => m.status === 'PASSED') ? 'PASSED' : 'FAILED',
        },
        null,
        2
      )
    );
    console.log('Performance measurements saved to', resultsFile);

    // Final assertion: All operations must satisfy their thresholds
    for (const [key, metric] of Object.entries(perfMetrics)) {
      expect(metric.status, `${key} failed threshold`).toBe('PASSED');
    }
  });
});
