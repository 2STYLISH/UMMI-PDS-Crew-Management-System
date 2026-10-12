import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

const SCREENSHOT_DIR = path.resolve(__dirname, '../../evidence/screenshots/cycle2/date_and_sea_service');
const TRACE_DIR = path.resolve(__dirname, '../../evidence/traces');

if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
if (!fs.existsSync(TRACE_DIR)) fs.mkdirSync(TRACE_DIR, { recursive: true });

// Load credentials directly from .env
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

async function login(page, username, password) {
  if (!username || !password) throw new Error(`Missing credentials for ${username}`);
  await page.context().clearCookies();
  await page.goto('/login.aspx', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#txtUsername', { timeout: 20000 });
  await page.fill('#txtUsername', username);
  await page.fill('#txtPassword', password);
  await Promise.all([
    page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 35000 }),
    page.click('#btnLogin')
  ]);
  await page.waitForLoadState('domcontentloaded');
}

test.describe.serial('Cycle 2 Focused: Availability Date Filter & Total Sea Service', () => {

  // ==========================================================================
  // Pre-test: Live Deployment Marker & Feature Servicing Confirmation
  // ==========================================================================
  test('Pre-test: Record Live Deployment Marker and Feature Servicing Confirmation', async ({ browser }) => {
    const page = await browser.newPage();
    let lastModified = '';
    let etag = '';

    page.on('response', res => {
      if (res.url().includes('site.css') || res.url().includes('site.js')) {
        lastModified = res.headers()['last-modified'] || lastModified;
        etag = res.headers()['etag'] || etag;
      }
    });

    await login(page, MANNING_CONTROL_USER, MANNING_CONTROL_PASS);
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);

    const title = await page.title();
    console.log(`[LIVE DEPLOYMENT MARKER] Last-Modified: ${lastModified} | ETag: ${etag} | Title: ${title}`);

    // Confirm txtAvailFrom and txtAvailTo exist in the DOM
    const hasAvailFrom = await page.locator('#ContentPlaceHolder1_txtAvailFrom').count();
    const hasAvailTo = await page.locator('#ContentPlaceHolder1_txtAvailTo').count();
    expect(hasAvailFrom).toBe(1);
    expect(hasAvailTo).toBe(1);

    // Confirm Sea Service column exists in search grid header
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2000);
    const headers = await page.locator('table[id*="GridViewQueryCrew"] th').allInnerTexts();
    expect(headers).toContain('SEA SERVICE');

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'staging-deployment-marker.png'),
      fullPage: true,
    });

    await page.close();
  });

  // ==========================================================================
  // TC-CM-036: Crew Search Availability-Date Range
  // ==========================================================================
  test('TC-CM-036: Crew Search Availability-Date Range Evaluation', async ({ browser }) => {
    const context = await browser.newContext({ acceptDownloads: true });
    const page = await context.newPage();
    await context.tracing.start({ screenshots: true, snapshots: true });

    await login(page, MANNING_CONTROL_USER, MANNING_CONTROL_PASS);
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);

    // 1. Assertion: Controls exist and have correct type
    const txtFrom = page.locator('#ContentPlaceHolder1_txtAvailFrom');
    const txtTo = page.locator('#ContentPlaceHolder1_txtAvailTo');
    await expect(txtFrom).toBeVisible();
    await expect(txtTo).toBeVisible();
    expect(await txtFrom.getAttribute('type')).toBe('date');
    expect(await txtTo.getAttribute('type')).toBe('date');

    // 2. Assertion: Reversed Range (From later than To) is rejected with clear validation message
    await txtFrom.fill('2026-12-31');
    await txtTo.fill('2026-01-01');
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2000);

    const errorAlert = page.locator('.alert-danger').first();
    const alertText = await errorAlert.innerText();
    console.log('[TC-CM-036] Reversed range validation text:', alertText);
    expect(alertText).toContain('Available From date cannot be later than Available To date');

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc036-reversed-range-validation.png'),
    });

    // 3. Assertion: Both boundaries empty leaves search open and returns baseline results
    await txtFrom.fill('');
    await txtTo.fill('');
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2000);

    const openRows = await page.locator('table[id*="GridViewQueryCrew"] tr').allInnerTexts();
    const baselineCount = openRows.length - 1;
    console.log(`[TC-CM-036] Open search baseline crew count: ${baselineCount}`);
    expect(baselineCount).toBeGreaterThan(0);

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc036-both-empty-open-search.png'),
    });

    // 4. Assertion: Boundary filtering evaluation & Missing Availability Dates rule
    // Under approved behavior: "Missing availability dates do not match when a boundary is supplied."
    // Testing boundary range: 2026-09-01 to 2026-09-30
    await txtFrom.fill('2026-09-01');
    await txtTo.fill('2026-09-30');
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2000);

    const filteredRows = await page.locator('table[id*="GridViewQueryCrew"] tr').allInnerTexts();
    const filteredCount = filteredRows.length - 1;
    console.log(`[TC-CM-036] Row count with boundary 2026-09-01 to 2026-09-30: ${filteredCount}`);

    // All existing staging crew records have missing/NULL availability dates in the queried field
    // Therefore, missing availability dates return 0 rows
    const gridText = await page.locator('table[id*="GridViewQueryCrew"]').innerText();
    expect(gridText).toContain('No crew found matching the search criteria');

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc036-missing-availability-boundary-filtered.png'),
    });

    // 5. Assertion: Search and Export Criteria Agreement
    // When filtered criteria yield no matching data, export indicates no data
    await page.click('#ContentPlaceHolder1_btnExportExcel');
    await page.waitForTimeout(1500);

    const exportNotify = await page.locator('span[id*="lblNotify"]').innerText();
    console.log('[TC-CM-036] Export notification with zero filtered data:', exportNotify);
    expect(exportNotify).toContain('No records found to export');

    // When empty boundaries yield matching data, export succeeds and matches criteria
    await txtFrom.fill('');
    await txtTo.fill('');
    await page.fill('#ContentPlaceHolder1_txtLastName', 'QA2B18_BatangasMatch');
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2000);

    const [download] = await Promise.all([
      page.waitForEvent('download'),
      page.click('#ContentPlaceHolder1_btnExportExcel')
    ]);

    const exportPath = path.join(SCREENSHOT_DIR, 'tc036-exported-search-result.xls');
    await download.saveAs(exportPath);
    expect(fs.existsSync(exportPath)).toBe(true);
    expect(fs.statSync(exportPath).size).toBeGreaterThan(1000);
    console.log(`[TC-CM-036] Export file successfully generated: ${exportPath} (${fs.statSync(exportPath).size} bytes)`);

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc036-export-criteria-agreement.png'),
    });

    await context.tracing.stop({ path: path.join(TRACE_DIR, 'tc036-avail-date-trace.zip') });
    await context.close();
  });

  // ==========================================================================
  // TC-CM-098: Total Sea Service Calculation Consistency
  // ==========================================================================
  test('TC-CM-098: Total Sea Service Calculation and Profile Consistency', async ({ browser }) => {
    const context = await browser.newContext();
    const page = await context.newPage();
    await context.tracing.start({ screenshots: true, snapshots: true });

    await login(page, MANNING_CONTROL_USER, MANNING_CONTROL_PASS);

    // ------------------------------------------------------------------------
    // Case A: Neither history nor contracts -> Gomez, Alfredo (Deck Cadet)
    // Independent Expected: 0 days -> 0 yr(s)
    // ------------------------------------------------------------------------
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    await page.fill('#ContentPlaceHolder1_txtLastName', 'Gomez');
    await page.fill('#ContentPlaceHolder1_txtFirstName', 'Alfredo');
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2000);

    const alfredoRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'Gomez, Alfredo' });
    await expect(alfredoRow).toBeVisible();
    const alfredoRowText = await alfredoRow.innerText();
    const alfredoGridCells = alfredoRowText.split('\t').map(c => c.trim());
    const alfredoGridSeaService = alfredoGridCells[8];
    console.log(`[TC-CM-098 Case A - Gomez, Alfredo] Grid Sea Service: '${alfredoGridSeaService}'`);
    expect(alfredoGridSeaService).toBe('0 yr(s)');

    const [alfredoPage] = await Promise.all([
      context.waitForEvent('page'),
      alfredoRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await alfredoPage.waitForLoadState('domcontentloaded');
    await alfredoPage.waitForTimeout(1500);

    const alfredoProfileChip = await alfredoPage.locator('span[id*="lblTotalService"]').innerText();
    console.log(`[TC-CM-098 Case A - Gomez, Alfredo] Profile Sea Service: '${alfredoProfileChip}'`);
    expect(alfredoProfileChip).toBe('0 yr(s)');
    expect(alfredoGridSeaService).toBe(alfredoProfileChip);

    await alfredoPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc098-alfredo-gomez-zero-service.png'),
    });
    await alfredoPage.close();

    // ------------------------------------------------------------------------
    // Case B: History only with separate periods and gap -> Aguilar, Gustavo
    // Independent Expected:
    // Period 1: 2023-01-15 to 2023-10-15 = 273 days
    // Period 2: 2024-02-01 to 2024-09-01 = 213 days
    // Gap: 2023-10-15 to 2024-02-01 = 108 days (excluded)
    // Total Days: 273 + 213 = 486 days
    // Expected Years: 486 / 365.25 = 1.33059 -> 1.3 yr(s)
    // ------------------------------------------------------------------------
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    await page.fill('#ContentPlaceHolder1_txtLastName', 'Aguilar');
    await page.fill('#ContentPlaceHolder1_txtFirstName', 'Gustavo');
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2000);

    const gustavoRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'Aguilar, Gustavo' });
    await expect(gustavoRow).toBeVisible();
    const gustavoRowText = await gustavoRow.innerText();
    const gustavoGridCells = gustavoRowText.split('\t').map(c => c.trim());
    const gustavoGridSeaService = gustavoGridCells[8];
    console.log(`[TC-CM-098 Case B - Aguilar, Gustavo] Grid Sea Service: '${gustavoGridSeaService}' (Expected: 1.3 yr(s))`);
    expect(gustavoGridSeaService).toBe('1.3 yr(s)');

    const [gustavoPage] = await Promise.all([
      context.waitForEvent('page'),
      gustavoRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await gustavoPage.waitForLoadState('domcontentloaded');
    await gustavoPage.waitForTimeout(1500);

    const gustavoProfileChip = await gustavoPage.locator('span[id*="lblTotalService"]').innerText();
    console.log(`[TC-CM-098 Case B - Aguilar, Gustavo] Profile Sea Service: '${gustavoProfileChip}'`);
    expect(gustavoProfileChip).toBe('1.3 yr(s)');
    expect(gustavoGridSeaService).toBe(gustavoProfileChip);

    await gustavoPage.click('button:has-text("Sea Service")');
    await gustavoPage.waitForTimeout(500);

    await gustavoPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc098-gustavo-aguilar-history-gap.png'),
    });
    await gustavoPage.close();

    // ------------------------------------------------------------------------
    // Case C: History & contracts with overlapping periods and ongoing contract
    // -> Garcia, Roberto Lim (Chief Engineer)
    // As-of Philippine Date: 2026-10-11
    // Independent Expected:
    // Sea Service Period 1: 2022-08-10 to 2023-08-09 = 364 days
    // Ongoing Company Contract: 2023-09-01 to 2026-10-11 = 1136 days
    // Overlapping Sea Service Period 2: 2025-09-12 to 2026-06-12 (273 days, wholly inside contract)
    // Merged: [2022-08-10..2023-08-09] (364d) + [2023-09-01..2026-10-11] (1136d) = 1500 days
    // Expected Years: 1500 / 365.25 = 4.10677 -> 4.1 yr(s)
    // ------------------------------------------------------------------------
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    await page.fill('#ContentPlaceHolder1_txtLastName', 'Garcia');
    await page.fill('#ContentPlaceHolder1_txtFirstName', 'Roberto');
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2000);

    const garciaRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'Garcia, Roberto' });
    await expect(garciaRow).toBeVisible();
    const garciaRowText = await garciaRow.innerText();
    const garciaGridCells = garciaRowText.split('\t').map(c => c.trim());
    const garciaGridSeaService = garciaGridCells[8];
    console.log(`[TC-CM-098 Case C - Garcia, Roberto] Grid Sea Service: '${garciaGridSeaService}' (Expected: 4.1 yr(s))`);
    expect(garciaGridSeaService).toBe('4.1 yr(s)');

    const [garciaPage] = await Promise.all([
      context.waitForEvent('page'),
      garciaRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await garciaPage.waitForLoadState('domcontentloaded');
    await garciaPage.waitForTimeout(1500);

    const garciaProfileChip = await garciaPage.locator('span[id*="lblTotalService"]').innerText();
    console.log(`[TC-CM-098 Case C - Garcia, Roberto] Profile Sea Service: '${garciaProfileChip}'`);
    expect(garciaProfileChip).toBe('4.1 yr(s)');
    expect(garciaGridSeaService).toBe(garciaProfileChip);

    await garciaPage.click('button:has-text("Sea Service")');
    await garciaPage.waitForTimeout(500);

    await garciaPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc098-roberto-garcia-overlap-contract.png'),
    });
    await garciaPage.close();

    // Full Grid Screenshot showing consistent Sea Service column
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    await page.fill('#ContentPlaceHolder1_txtLastName', '');
    await page.fill('#ContentPlaceHolder1_txtFirstName', '');
    await page.click('input[id*="btnSearch"]');
    await page.waitForTimeout(2000);

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc098-querycrew-sea-service-grid.png'),
    });

    await context.tracing.stop({ path: path.join(TRACE_DIR, 'tc098-sea-service-trace.zip') });
    await context.close();
  });

});
