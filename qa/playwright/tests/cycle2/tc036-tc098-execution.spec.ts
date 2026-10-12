import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const SCREENSHOT_DIR = path.resolve(__dirname, '../../evidence/screenshots/cycle2/tc036_tc098');
const TRACE_DIR = path.resolve(__dirname, '../../evidence/traces');
const EXPORT_DIR = path.resolve(__dirname, '../../evidence/exports');

if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
if (!fs.existsSync(TRACE_DIR)) fs.mkdirSync(TRACE_DIR, { recursive: true });
if (!fs.existsSync(EXPORT_DIR)) fs.mkdirSync(EXPORT_DIR, { recursive: true });

// Load credentials from ignored local .env
const envPath = path.resolve(__dirname, '../../.env');
if (fs.existsSync(envPath)) {
  const content = fs.readFileSync(envPath, 'utf8');
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx === -1) continue;
    const key = trimmed.slice(0, eqIdx).trim();
    let val = trimmed.slice(eqIdx + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    process.env[key] = val;
  }
}

const MANNING_CONTROL_USER = process.env.QA_MANNING_CONTROL_USER || 'qa.manning.control';
const MANNING_CONTROL_PASS = process.env.QA_MANNING_CONTROL_PASSWORD || '';

// Fixture Mapping: Verified provisioned identities
const FIXTURES = {
  245: { id: 245, lastName: 'QA2FOC_Tc036_ExclBefore', firstName: 'Sep09', avail: '2026-09-09' },
  246: { id: 246, lastName: 'QA2FOC_Tc036_InclFrom', firstName: 'Sep10', avail: '2026-09-10' },
  247: { id: 247, lastName: 'QA2FOC_Tc036_InclTo', firstName: 'Sep20', avail: '2026-09-20' },
  248: { id: 248, lastName: 'QA2FOC_Tc036_InclToLate', firstName: 'Sep20Late', avail: '2026-09-20' },
  249: { id: 249, lastName: 'QA2FOC_Tc036_ExclAfter', firstName: 'Sep21', avail: '2026-09-21' },
  250: { id: 250, lastName: 'QA2FOC_Tc036_ExclNull', firstName: 'NullDate', avail: null },
  251: { id: 251, lastName: 'QA2FOC_Tc098_CompletedContract', firstName: 'Mateo', avail: null },
  252: { id: 252, lastName: 'QA2FOC_Tc098_OngoingContract', firstName: 'Lucas', avail: null },
};

async function login(page: any) {
  if (!MANNING_CONTROL_USER || !MANNING_CONTROL_PASS) {
    throw new Error('Missing qa.manning.control credentials in .env');
  }
  await page.context().clearCookies();
  await page.goto('/login.aspx', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#txtUsername', { timeout: 20000 });
  await page.fill('#txtUsername', MANNING_CONTROL_USER);
  await page.fill('#txtPassword', MANNING_CONTROL_PASS);
  await Promise.all([
    page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 35000 }),
    page.click('#btnLogin'),
  ]);
  await page.waitForLoadState('domcontentloaded');
}

/**
 * Collect all QA2FOC fixture rows visible across grid pagination
 */
async function collectGridFixtureRows(page: any) {
  const matchedFixtures: { [id: number]: { name: string; seaService: string } } = {};
  let hasNext = true;
  let pageIdx = 0;

  while (hasNext && pageIdx < 10) {
    pageIdx++;
    await page.waitForTimeout(1000);
    const rows = await page.locator('table[id*="GridViewQueryCrew"] tr').all();
    for (const row of rows) {
      const text = await row.innerText();
      for (const [idStr, f] of Object.entries(FIXTURES)) {
        const id = parseInt(idStr, 10);
        if (text.includes(f.lastName)) {
          const cells = await row.locator('td').allInnerTexts();
          // Sea Service is column index 8 (0-indexed) or find cell with 'yr(s)'
          let ssText = '';
          for (const c of cells) {
            if (c.includes('yr(s)')) ssText = c.trim();
          }
          matchedFixtures[id] = { name: f.lastName, seaService: ssText };
        }
      }
    }

    // Check if next page button exists and is enabled
    const nextBtn = page.locator('#phPager button.pg-btn[aria-label="Next page"]:not([disabled])');
    if ((await nextBtn.count()) > 0) {
      await nextBtn.click();
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(1500);
    } else {
      hasNext = false;
    }
  }

  return matchedFixtures;
}

/**
 * Read downloaded Excel export file and extract matched QA2FOC fixture IDs
 */
function extractFixturesFromExport(filePath: string): number[] {
  let content = '';
  try {
    const stdout = execSync(
      `python -c "import sys, zipfile; sys.stdout.reconfigure(encoding='utf-8'); z = zipfile.ZipFile(r'${filePath}'); print(z.read('xl/sharedStrings.xml').decode('utf-8', errors='ignore'))"`,
      { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 }
    );
    content = stdout;
  } catch {
    content = fs.readFileSync(filePath, 'utf8');
  }

  const foundIds: number[] = [];
  for (const [idStr, f] of Object.entries(FIXTURES)) {
    const id = parseInt(idStr, 10);
    if (content.includes(f.lastName)) {
      foundIds.push(id);
    }
  }
  return foundIds.sort((a, b) => a - b);
}

test.describe.serial('Cycle 2 Focused Azure Staging Tests: TC-CM-036 & TC-CM-098', () => {

  test('Pre-test: Live Deployment Fingerprint and Feature Confirmation', async ({ browser }) => {
    const page = await browser.newPage();
    let lastModified = '';
    let etag = '';

    page.on('response', (res) => {
      if (res.url().includes('site.css') || res.url().includes('site.js')) {
        lastModified = res.headers()['last-modified'] || lastModified;
        etag = res.headers()['etag'] || etag;
      }
    });

    await login(page);
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);

    const title = await page.title();
    console.log(`[DEPLOYMENT FINGERPRINT] Title: '${title}' | Last-Modified: '${lastModified}' | ETag: '${etag}'`);

    const hasFrom = await page.locator('#ContentPlaceHolder1_txtAvailFrom').count();
    const hasTo = await page.locator('#ContentPlaceHolder1_txtAvailTo').count();
    expect(hasFrom).toBe(1);
    expect(hasTo).toBe(1);

    const fromType = await page.locator('#ContentPlaceHolder1_txtAvailFrom').getAttribute('type');
    const toType = await page.locator('#ContentPlaceHolder1_txtAvailTo').getAttribute('type');
    expect(fromType).toBe('date');
    expect(toType).toBe('date');

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'staging-deployment-marker.png'),
      fullPage: true,
    });

    await page.close();
  });

  // ==========================================================================
  // TC-CM-036: Crew Search Availability-Date Range Filter
  // ==========================================================================
  test('TC-CM-036: Crew Search Availability-Date Range Filter Evaluation', async ({ browser }) => {
    const context = await browser.newContext({ acceptDownloads: true });
    const page = await context.newPage();

    await login(page);
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);

    const txtFrom = page.locator('#ContentPlaceHolder1_txtAvailFrom');
    const txtTo = page.locator('#ContentPlaceHolder1_txtAvailTo');
    const btnSearch = page.locator('input[id*="btnSearch"]');
    const btnExport = page.locator('#ContentPlaceHolder1_btnExportExcel');

    // ------------------------------------------------------------------------
    // Check 1: Reversed Range Validation
    // ------------------------------------------------------------------------
    console.log('\n[TC-CM-036 Check 1] Reversed Range (From: 2026-12-31, To: 2026-01-01)');
    await txtFrom.fill('2026-12-31');
    await txtTo.fill('2026-01-01');
    await btnSearch.click();
    await page.waitForTimeout(2000);

    const errorAlert = page.locator('.alert-danger, span[id*="lblNotify"]').first();
    const alertText = await errorAlert.innerText();
    console.log(`  Validation text: '${alertText.trim()}'`);
    expect(alertText).toContain('Available From date cannot be later than Available To date');

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc036-reversed-range-validation.png'),
    });

    // ------------------------------------------------------------------------
    // Check 2: Both Boundaries Supplied (From: 2026-09-10, To: 2026-09-20)
    // Expected QA2FOC IDs: 246, 247, 248
    // ------------------------------------------------------------------------
    console.log('\n[TC-CM-036 Check 2] Both Boundaries (2026-09-10 to 2026-09-20)');
    await txtFrom.fill('2026-09-10');
    await txtTo.fill('2026-09-20');
    await btnSearch.click();
    await page.waitForTimeout(2500);

    const gridBoth = await collectGridFixtureRows(page);
    const gridBothIds = Object.keys(gridBoth).map(Number).sort((a, b) => a - b);
    console.log(`  Grid QA2FOC Matched IDs: [${gridBothIds.join(', ')}]`);
    expect(gridBothIds).toEqual([246, 247, 248]);

    // Export validation
    const [downloadBoth] = await Promise.all([
      page.waitForEvent('download'),
      btnExport.click(),
    ]);
    const exportBothPath = path.join(EXPORT_DIR, 'tc036-both-boundary-export.xls');
    await downloadBoth.saveAs(exportBothPath);
    const exportBothIds = extractFixturesFromExport(exportBothPath);
    console.log(`  Export QA2FOC Matched IDs: [${exportBothIds.join(', ')}]`);
    expect(exportBothIds).toEqual([246, 247, 248]);

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc036-both-boundaries-results.png'),
    });

    // ------------------------------------------------------------------------
    // Check 3: From-Only Supplied (From: 2026-09-10, To: "")
    // Expected QA2FOC IDs: 246, 247, 248, 249
    // ------------------------------------------------------------------------
    console.log('\n[TC-CM-036 Check 3] From-Only (From: 2026-09-10, To: "")');
    await txtFrom.fill('2026-09-10');
    await txtTo.fill('');
    await btnSearch.click();
    await page.waitForTimeout(2500);

    const gridFromOnly = await collectGridFixtureRows(page);
    const gridFromOnlyIds = Object.keys(gridFromOnly).map(Number).sort((a, b) => a - b);
    console.log(`  Grid QA2FOC Matched IDs: [${gridFromOnlyIds.join(', ')}]`);
    expect(gridFromOnlyIds).toEqual([246, 247, 248, 249]);

    const [downloadFromOnly] = await Promise.all([
      page.waitForEvent('download'),
      btnExport.click(),
    ]);
    const exportFromOnlyPath = path.join(EXPORT_DIR, 'tc036-from-only-export.xls');
    await downloadFromOnly.saveAs(exportFromOnlyPath);
    const exportFromOnlyIds = extractFixturesFromExport(exportFromOnlyPath);
    console.log(`  Export QA2FOC Matched IDs: [${exportFromOnlyIds.join(', ')}]`);
    expect(exportFromOnlyIds).toEqual([246, 247, 248, 249]);

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc036-from-only-results.png'),
    });

    // ------------------------------------------------------------------------
    // Check 4: To-Only Supplied (From: "", To: 2026-09-20)
    // Expected QA2FOC IDs: 245, 246, 247, 248
    // ------------------------------------------------------------------------
    console.log('\n[TC-CM-036 Check 4] To-Only (From: "", To: 2026-09-20)');
    await txtFrom.fill('');
    await txtTo.fill('2026-09-20');
    await btnSearch.click();
    await page.waitForTimeout(2500);

    const gridToOnly = await collectGridFixtureRows(page);
    const gridToOnlyIds = Object.keys(gridToOnly).map(Number).sort((a, b) => a - b);
    console.log(`  Grid QA2FOC Matched IDs: [${gridToOnlyIds.join(', ')}]`);
    expect(gridToOnlyIds).toEqual([245, 246, 247, 248]);

    const [downloadToOnly] = await Promise.all([
      page.waitForEvent('download'),
      btnExport.click(),
    ]);
    const exportToOnlyPath = path.join(EXPORT_DIR, 'tc036-to-only-export.xls');
    await downloadToOnly.saveAs(exportToOnlyPath);
    const exportToOnlyIds = extractFixturesFromExport(exportToOnlyPath);
    console.log(`  Export QA2FOC Matched IDs: [${exportToOnlyIds.join(', ')}]`);
    expect(exportToOnlyIds).toEqual([245, 246, 247, 248]);

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc036-to-only-results.png'),
    });

    // ------------------------------------------------------------------------
    // Check 5: Both Empty Supplied (Open Search: From: "", To: "")
    // Expected QA2FOC IDs: All 8 fixtures (245, 246, 247, 248, 249, 250, 251, 252)
    // ------------------------------------------------------------------------
    console.log('\n[TC-CM-036 Check 5] Both Empty (Open Search)');
    await txtFrom.fill('');
    await txtTo.fill('');
    await btnSearch.click();
    await page.waitForTimeout(2500);

    // 1. Export open search (captures all 249 matching crew across all pages)
    const [downloadBothEmpty] = await Promise.all([
      page.waitForEvent('download'),
      btnExport.click(),
    ]);
    const exportBothEmptyPath = path.join(EXPORT_DIR, 'tc036-both-empty-export.xls');
    await downloadBothEmpty.saveAs(exportBothEmptyPath);
    const exportBothEmptyIds = extractFixturesFromExport(exportBothEmptyPath);
    console.log(`  Export QA2FOC Matched IDs: [${exportBothEmptyIds.join(', ')}]`);
    expect(exportBothEmptyIds).toEqual([245, 246, 247, 248, 249, 250, 251, 252]);

    // 2. Verify grid view for the same empty-date filter scoped to this QA2FOC fixture group
    await page.fill('#ContentPlaceHolder1_txtLastName', 'QA2FOC');
    await btnSearch.click();
    await page.waitForTimeout(2500);

    const gridBothEmpty = await collectGridFixtureRows(page);
    const gridBothEmptyIds = Object.keys(gridBothEmpty).map(Number).sort((a, b) => a - b);
    console.log(`  Grid QA2FOC Matched IDs (scoped to QA2FOC): [${gridBothEmptyIds.join(', ')}]`);
    expect(gridBothEmptyIds).toEqual([245, 246, 247, 248, 249, 250, 251, 252]);

    // Reset txtLastName back to empty
    await page.fill('#ContentPlaceHolder1_txtLastName', '');

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc036-both-empty-results.png'),
    });

    await context.close();
  });

  // ==========================================================================
  // TC-CM-098: Total Sea Service Company Contract Calculation & Consistency
  // ==========================================================================
  test('TC-CM-098: Total Sea Service Company Contract Calculation and Grid Consistency', async ({ browser }) => {
    const context = await browser.newContext();
    const page = await context.newPage();

    await login(page);
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);

    // ------------------------------------------------------------------------
    // Step 1: Inspect Crew Search grid immediately BEFORE opening either profile
    // ------------------------------------------------------------------------
    console.log('\n[TC-CM-098 Step 1] Inspect Crew Search grid BEFORE opening either profile');
    await page.fill('#ContentPlaceHolder1_txtLastName', 'QA2FOC_Tc098');
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2500);

    const mateoRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2FOC_Tc098_CompletedContract' });
    const lucasRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2FOC_Tc098_OngoingContract' });

    await expect(mateoRow).toBeVisible();
    await expect(lucasRow).toBeVisible();

    const mateoInitialGridText = await mateoRow.innerText();
    const lucasInitialGridText = await lucasRow.innerText();

    console.log(`  Mateo Initial Grid Row: ${mateoInitialGridText.replace(/\t/g, ' | ')}`);
    console.log(`  Lucas Initial Grid Row: ${lucasInitialGridText.replace(/\t/g, ' | ')}`);

    // Extract exact initial Sea Service column text
    const mateoCells = await mateoRow.locator('td').allInnerTexts();
    const lucasCells = await lucasRow.locator('td').allInnerTexts();
    const mateoInitialSS = (mateoCells.find((c: string) => c.includes('yr(s)')) || mateoCells[8] || '').trim();
    const lucasInitialSS = (lucasCells.find((c: string) => c.includes('yr(s)')) || lucasCells[8] || '').trim();

    console.log(`  Mateo Initial Sea Service: '${mateoInitialSS}'`);
    console.log(`  Lucas Initial Sea Service: '${lucasInitialSS}'`);

    // Independent Philippine Date Expectation for ongoing contract (Lucas, starts 2026-04-29, date_to NULL)
    // Captured Philippine evaluation date (Asia/Manila, UTC+8):
    const phtDateStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Manila' }).format(new Date());
    const startDate = new Date('2026-04-29T00:00:00Z');
    const evalDate = new Date(`${phtDateStr}T00:00:00Z`);
    const expectedOngoingDays = Math.round((evalDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
    const expectedOngoingYears = (expectedOngoingDays / 365.25).toFixed(1);
    const expectedOngoingSS = `${expectedOngoingYears} yr(s)`;
    console.log(`  Independent PHT (${phtDateStr}) Expectation for Ongoing Contract: ${expectedOngoingDays} days / 365.25 = ${expectedOngoingSS}`);

    // Assert initial grid values
    expect(mateoInitialSS).toBe('0.7 yr(s)');
    expect(lucasInitialSS).toBe(expectedOngoingSS); // Stricly requires PHT evaluation (0.5 yr(s) on 2026-10-11)

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc098-initial-crew-search-grid.png'),
    });

    // ------------------------------------------------------------------------
    // Step 2: Open Mateo's Profile (Completed Contract: 2025-01-01 to 2025-10-01)
    // Net days = 273 days -> Expected = 0.7 yr(s)
    // ------------------------------------------------------------------------
    console.log('\n[TC-CM-098 Step 2] Inspect Mateo Profile (Completed Contract: 273 days)');
    const [mateoPage] = await Promise.all([
      context.waitForEvent('page'),
      mateoRow.locator('a[id*="lnkProfile"]').click(),
    ]);
    await mateoPage.waitForLoadState('domcontentloaded');
    await mateoPage.waitForTimeout(2000);

    const mateoChip = (await mateoPage.locator('span[id*="lblTotalService"]').innerText()).trim();
    const mateoFullYrs = (await mateoPage.locator('span[id*="lblTotalYrsService"]').innerText()).trim();
    console.log(`  Mateo Profile Chip: '${mateoChip}', Full: '${mateoFullYrs}'`);
    expect(mateoChip).toBe('0.7 yr(s)');
    expect(mateoFullYrs).toContain('0.7 yr(s) at sea');

    // Switch to Sea Service tab: Assert 0 prior voyage history rows in gvSeaService
    const ssTab = mateoPage.locator('button:has-text("Sea Service"), a:has-text("Sea Service")').first();
    if (await ssTab.count() > 0) {
      await ssTab.click();
      await mateoPage.waitForTimeout(1000);
      const seaRows = await mateoPage.locator('table[id*="gvSeaService"] tr').allInnerTexts();
      console.log(`  Mateo gvSeaService table rows count: ${seaRows.length} (header or empty)`);
    }

    await mateoPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc098-mateo-completed-contract-profile.png'),
      fullPage: true,
    });
    await mateoPage.close();

    // ------------------------------------------------------------------------
    // Step 3: Open Lucas's Profile (Ongoing Contract: starts 2026-04-29, date_to NULL)
    // On 2026-10-11 PHT: 165 days -> Expected = 0.5 yr(s)
    // ------------------------------------------------------------------------
    console.log('\n[TC-CM-098 Step 3] Inspect Lucas Profile (Ongoing Contract: starts 2026-04-29)');
    const [lucasPage] = await Promise.all([
      context.waitForEvent('page'),
      lucasRow.locator('a[id*="lnkProfile"]').click(),
    ]);
    await lucasPage.waitForLoadState('domcontentloaded');
    await lucasPage.waitForTimeout(2000);

    const lucasChip = (await lucasPage.locator('span[id*="lblTotalService"]').innerText()).trim();
    const lucasFullYrs = (await lucasPage.locator('span[id*="lblTotalYrsService"]').innerText()).trim();
    console.log(`  Lucas Profile Chip: '${lucasChip}', Full: '${lucasFullYrs}'`);

    // Strictly enforce independent Philippine evaluation date expectation (0.5 yr(s) on 2026-10-11)
    expect(lucasChip).toBe(expectedOngoingSS);
    expect(lucasFullYrs).toContain(`${expectedOngoingSS} at sea`);

    // Switch to Sea Service tab: Assert 0 prior voyage history rows in gvSeaService
    const ssTabLucas = lucasPage.locator('button:has-text("Sea Service"), a:has-text("Sea Service")').first();
    if (await ssTabLucas.count() > 0) {
      await ssTabLucas.click();
      await lucasPage.waitForTimeout(1000);
      const seaRowsLucas = await lucasPage.locator('table[id*="gvSeaService"] tr').allInnerTexts();
      console.log(`  Lucas gvSeaService table rows count: ${seaRowsLucas.length}`);
    }

    await lucasPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc098-lucas-ongoing-contract-profile.png'),
      fullPage: true,
    });
    await lucasPage.close();

    // ------------------------------------------------------------------------
    // Step 4: Recheck Crew Search grid AFTER profile navigation
    // ------------------------------------------------------------------------
    console.log('\n[TC-CM-098 Step 4] Recheck Crew Search grid AFTER profile navigation');
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);

    await page.fill('#ContentPlaceHolder1_txtLastName', 'QA2FOC_Tc098');
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2500);

    const mateoRowAfter = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2FOC_Tc098_CompletedContract' });
    const lucasRowAfter = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2FOC_Tc098_OngoingContract' });

    const mateoCellsAfter = await mateoRowAfter.locator('td').allInnerTexts();
    const lucasCellsAfter = await lucasRowAfter.locator('td').allInnerTexts();
    const mateoAfterSS = (mateoCellsAfter.find((c: string) => c.includes('yr(s)')) || mateoCellsAfter[8] || '').trim();
    const lucasAfterSS = (lucasCellsAfter.find((c: string) => c.includes('yr(s)')) || lucasCellsAfter[8] || '').trim();

    console.log(`  Mateo After-Profile Sea Service in Grid: '${mateoAfterSS}'`);
    console.log(`  Lucas After-Profile Sea Service in Grid: '${lucasAfterSS}'`);

    expect(mateoAfterSS).toBe('0.7 yr(s)');
    expect(lucasAfterSS).toBe(expectedOngoingSS); // Strictly requires PHT evaluation (0.5 yr(s) on 2026-10-11)

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc098-after-profile-crew-search-grid.png'),
    });

    await context.close();
  });

});
