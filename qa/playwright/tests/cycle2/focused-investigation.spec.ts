import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

const SCREENSHOT_DIR = path.resolve(__dirname, '../../evidence/screenshots/cycle2/batch18');
const TRACE_DIR = path.resolve(__dirname, '../../evidence/traces');

if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
if (!fs.existsSync(TRACE_DIR)) fs.mkdirSync(TRACE_DIR, { recursive: true });

async function loginAs(page, username, password) {
  if (!username || !password) throw new Error(`Missing credentials for login: ${username}`);
  await page.context().clearCookies();
  await page.goto('/login.aspx', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#txtUsername', { timeout: 15000 });
  await page.fill('#txtUsername', username);
  await page.fill('#txtPassword', password);
  await page.click('#btnLogin');
  await page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 20000 });
}

test.describe.serial('Cycle 2 Focused Investigation Suite (Azure Staging)', () => {

  // ==========================================================================
  // TC-CM-036: Crew search date range includes start and end dates
  // ==========================================================================
  test('TC-CM-036: Date range filter evaluation on QueryCrew.aspx', async ({ page }) => {
    const user = process.env.UMMI_MANNING_USER || 'demo.manning';
    const pass = process.env.UMMI_MANNING_PASSWORD;

    await page.context().tracing.start({ screenshots: true, snapshots: true });

    await loginAs(page, user, pass);

    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    // 1. Inspect search filters panel
    const filterPanel = page.locator('.filter-panel');
    await expect(filterPanel).toBeVisible();

    // 2. Query for date-related inputs
    const dateInputs = filterPanel.locator('input[type="date"], input[id*="Date"], input[placeholder*="date" i]');
    const dateInputCount = await dateInputs.count();

    // 3. Query all filter labels in panel
    const filterLabels = await filterPanel.locator('label').allInnerTexts();
    console.log('[TC-CM-036] Filter labels on QueryCrew:', filterLabels);
    console.log('[TC-CM-036] Date input controls count in filter panel:', dateInputCount);

    // Assert that date input controls (Available From, Available To) ARE present on deployed page
    expect(dateInputCount).toBe(2);

    // 4. Test baseline count with open search
    await page.locator('input[id*="btnSearch"]').click();
    await page.waitForLoadState('networkidle');
    const openRows = await page.locator('table[id*="GridViewQueryCrew"] tr').allInnerTexts();
    const baselineCount = openRows.length;
    console.log(`[TC-CM-036] Baseline open search row count: ${baselineCount}`);

    // 5. Test date filter behavior: enter narrow range (e.g. 2024-01-01 to 2024-01-02)
    await page.fill('input[id*="txtAvailFrom"]', '2024-01-01');
    await page.fill('input[id*="txtAvailTo"]', '2024-01-02');
    await page.locator('input[id*="btnSearch"]').click();
    await page.waitForLoadState('networkidle');

    const filteredRows = await page.locator('table[id*="GridViewQueryCrew"] tr').allInnerTexts();
    const filteredCount = filteredRows.length;
    console.log(`[TC-CM-036] Row count with date range 2024-01-01 to 2024-01-02: ${filteredCount}`);

    // Capture screenshot of filter panel and results
    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc036-querycrew-filter-panel.png'),
      fullPage: true,
    });

    await page.context().tracing.stop({
      path: path.join(TRACE_DIR, 'tc036-trace.zip'),
    });

    // The deployed application ignores the date inputs (filteredCount equals baselineCount).
    // Assert that the filter fails to narrow results (documenting the defect/gap).
    expect(filteredCount).toBe(baselineCount);
  });

  // ==========================================================================
  // TC-CM-077: BMI classification boundaries and badge colors
  // ==========================================================================
  test('TC-CM-077: BMI classification boundaries and badge colors on ProfileViewer.aspx', async ({ page }) => {
    const user = process.env.UMMI_MANNING_USER || 'demo.manning';
    const pass = process.env.UMMI_MANNING_PASSWORD;

    await page.context().tracing.start({ screenshots: true, snapshots: true });

    await loginAs(page, user, pass);

    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    // Search for A001 fixture: QA Maria Santos
    await page.fill('input[id*="txtLastName"]', 'Santos');
    await page.locator('input[id*="btnSearch"]').click();
    await page.waitForLoadState('networkidle');

    // 1. Inspect Santos, Paciano (Overweight boundary verification)
    const pacianoRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'Santos, Paciano' }).first();
    await expect(pacianoRow).toBeVisible();

    const [pacianoPage] = await Promise.all([
      page.context().waitForEvent('page'),
      pacianoRow.locator('a[id*="lnkProfile"]').click(),
    ]);
    await pacianoPage.waitForLoadState('networkidle');

    const pacianoName = await pacianoPage.locator('span[id*="lblFullName"]').innerText();
    const pacianoH = await pacianoPage.locator('span[id$="lblHeight"]').innerText();
    const pacianoW = await pacianoPage.locator('span[id$="lblWeight"]').innerText();
    const pacianoBMI = await pacianoPage.locator('span[id$="lblBMI"]').innerText();
    const pacianoClass = await pacianoPage.locator('span[id$="lblBMIClass"]').innerText();
    const pacianoBadge = await pacianoPage.locator('span[id$="lblBMIClass"]').getAttribute('class');

    console.log(`[TC-CM-077] Crew 1: ${pacianoName} | H: ${pacianoH} cm, W: ${pacianoW} kg | BMI: ${pacianoBMI} | Class: ${pacianoClass} | Badge: ${pacianoBadge}`);

    // Verify formula & Overweight classification (25.0 <= BMI < 30.0)
    // 79 / (1.74^2) = 26.093... -> 26.1
    expect(parseFloat(pacianoBMI)).toBe(26.1);
    expect(pacianoClass).toBe('Overweight');
    expect(pacianoBadge).toContain('bmi-overweight');

    await pacianoPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc077-bmi-overweight-paciano.png'),
      fullPage: true,
    });
    await pacianoPage.close();

    // 2. Inspect Aguilar, Gustavo (Normal boundary verification)
    await page.fill('input[id*="txtLastName"]', 'Aguilar');
    await page.locator('input[id*="btnSearch"]').click();
    await page.waitForLoadState('networkidle');

    const aguilarRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'Aguilar, Gustavo' }).first();
    await expect(aguilarRow).toBeVisible();

    const [aguilarPage] = await Promise.all([
      page.context().waitForEvent('page'),
      aguilarRow.locator('a[id*="lnkProfile"]').click(),
    ]);
    await aguilarPage.waitForLoadState('networkidle');

    const aguilarName = await aguilarPage.locator('span[id*="lblFullName"]').innerText();
    const aguilarH = await aguilarPage.locator('span[id$="lblHeight"]').innerText();
    const aguilarW = await aguilarPage.locator('span[id$="lblWeight"]').innerText();
    const aguilarBMI = await aguilarPage.locator('span[id$="lblBMI"]').innerText();
    const aguilarClass = await aguilarPage.locator('span[id$="lblBMIClass"]').innerText();
    const aguilarBadge = await aguilarPage.locator('span[id$="lblBMIClass"]').getAttribute('class');

    console.log(`[TC-CM-077] Crew 2: ${aguilarName} | H: ${aguilarH} cm, W: ${aguilarW} kg | BMI: ${aguilarBMI} | Class: ${aguilarClass} | Badge: ${aguilarBadge}`);

    // Verify formula & Normal classification (18.5 <= BMI < 25.0)
    // 62 / (1.72^2) = 20.957... -> 21.0
    expect(parseFloat(aguilarBMI)).toBe(21.0);
    expect(aguilarClass).toBe('Normal');
    expect(aguilarBadge).toContain('bmi-normal');

    await aguilarPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc077-bmi-normal-aguilar.png'),
      fullPage: true,
    });

    await page.context().tracing.stop({
      path: path.join(TRACE_DIR, 'tc077-trace.zip'),
    });

    await aguilarPage.close();
  });

  // ==========================================================================
  // TC-CM-098: Total sea service with active/unfinished company contract
  // ==========================================================================
  test('TC-CM-098: Company contracts and total sea service calculation', async ({ page }) => {
    const user = process.env.UMMI_MANNING_USER || 'demo.manning';
    const pass = process.env.UMMI_MANNING_PASSWORD;

    await page.context().tracing.start({ screenshots: true, snapshots: true });

    await loginAs(page, user, pass);

    // Check Case A: Alfredo Gomez (Deck Cadet: 0 prior sea service records, 0 contracts -> 0 yrs)
    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    await page.fill('input[id*="txtLastName"]', 'Gomez');
    await page.locator('input[id*="btnSearch"]').click();
    await page.waitForLoadState('networkidle');

    const alfredoRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'Alfredo' });
    await expect(alfredoRow).toBeVisible();

    const [alfredoPage] = await Promise.all([
      page.context().waitForEvent('page'),
      alfredoRow.locator('a[id*="lnkProfile"]').click(),
    ]);
    await alfredoPage.waitForLoadState('networkidle');

    const alfredoChip = await alfredoPage.locator('span[id*="lblTotalService"]').innerText();
    console.log(`[TC-CM-098] Alfredo Gomez (0 history): Total Service Chip = ${alfredoChip}`);

    expect(alfredoChip).toMatch(/0 yr(\(s\)|s)/);

    await alfredoPage.close();

    // Check Case B: Roberto Garcia (Has active contract in tbl_contracts starting 09/01/2023 without date_to)
    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    await page.fill('input[id*="txtLastName"]', 'Garcia');
    await page.locator('input[id*="btnSearch"]').click();
    await page.waitForLoadState('networkidle');

    const garciaRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'Garcia, Roberto' });
    await expect(garciaRow).toBeVisible();
    const garciaGridText = await garciaRow.innerText();
    console.log(`[TC-CM-098] Roberto Garcia in QueryCrew grid: ${garciaGridText.replace(/\t/g, ' | ')}`);

    const [garciaPage] = await Promise.all([
      page.context().waitForEvent('page'),
      garciaRow.locator('a[id*="lnkProfile"]').click(),
    ]);
    await garciaPage.waitForLoadState('networkidle');

    const garciaChip = await garciaPage.locator('span[id*="lblTotalService"]').innerText();
    console.log(`[TC-CM-098] Roberto Garcia (with active contract): Total Service Chip = ${garciaChip}`);

    // Switch to Sea Service tab
    await garciaPage.click('button:has-text("Sea Service")');
    await garciaPage.waitForTimeout(500);

    const garciaSeaRows = await garciaPage.locator('table[id*="gvSeaService"] tr').allInnerTexts();
    console.log('[TC-CM-098] Roberto Garcia Sea Service grid rows:', garciaSeaRows);

    // Observe difference: QueryCrew shows 1.7 yr(s) (only tbl_personnel_sea_service),
    // but ProfileViewer shows 4.1 yr(s) because LoadTotalService dynamically incorporates active contract!
    expect(garciaChip).not.toBe('0 yr(s)');
    expect(garciaChip).toMatch(/4\.[0-9] yr(\(s\)|s)/);

    await garciaPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc098-contract-sea-service.png'),
      fullPage: true,
    });

    await page.context().tracing.stop({
      path: path.join(TRACE_DIR, 'tc098-trace.zip'),
    });

    await garciaPage.close();
  });

  // ==========================================================================
  // TC-CM-099: Additional PDS-only columns in Sea Service and role visibility
  // ==========================================================================
  test('TC-CM-099: Additional PDS-only columns evaluation across roles', async ({ page }) => {
    await page.context().tracing.start({ screenshots: true, snapshots: true });

    // Step 1: Login as Manning Staff (Non-PDS internal staff)
    const manningUser = process.env.UMMI_MANNING_USER || 'demo.manning';
    const manningPass = process.env.UMMI_MANNING_PASSWORD;
    await loginAs(page, manningUser, manningPass);

    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    await page.locator('input[id*="btnSearch"]').click();
    await page.waitForLoadState('networkidle');

    const manningProfileLink = page.locator('table[id*="GridViewQueryCrew"] a[id*="lnkProfile"]').first();
    const [manningProfilePage] = await Promise.all([
      page.context().waitForEvent('page'),
      manningProfileLink.click(),
    ]);
    await manningProfilePage.waitForLoadState('networkidle');

    await manningProfilePage.click('button:has-text("Sea Service")');
    await manningProfilePage.waitForTimeout(500);

    const manningHeaders = await manningProfilePage.locator('table[id*="gvSeaService"] th').allInnerTexts();
    console.log('[TC-CM-099] Manning Staff Sea Service Headers:', manningHeaders);

    await manningProfilePage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc099-manning-sea-service-columns.png'),
      fullPage: true,
    });
    await manningProfilePage.close();

    // Step 2: Switch to Admin (PDS-authorized role)
    const adminUser = process.env.UMMI_ADMIN_USER || 'demo.admin';
    const adminPass = process.env.UMMI_ADMIN_PASSWORD;
    await loginAs(page, adminUser, adminPass);

    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    await page.locator('input[id*="btnSearch"]').click();
    await page.waitForLoadState('networkidle');

    const adminProfileLink = page.locator('table[id*="GridViewQueryCrew"] a[id*="lnkProfile"]').first();
    const [adminProfilePage] = await Promise.all([
      page.context().waitForEvent('page'),
      adminProfileLink.click(),
    ]);
    await adminProfilePage.waitForLoadState('networkidle');

    await adminProfilePage.click('button:has-text("Sea Service")');
    await adminProfilePage.waitForTimeout(500);

    const adminHeaders = await adminProfilePage.locator('table[id*="gvSeaService"] th').allInnerTexts();
    console.log('[TC-CM-099] Admin Staff Sea Service Headers:', adminHeaders);

    await adminProfilePage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc099-admin-sea-service-columns.png'),
      fullPage: true,
    });

    await page.context().tracing.stop({
      path: path.join(TRACE_DIR, 'tc099-trace.zip'),
    });

    await adminProfilePage.close();

    // Assert that headers are identical between Manning Staff and Admin:
    // Both render: ['VESSEL', 'RANK', 'PORT', 'SIGN-ON', 'SIGN-OFF', 'PERIOD', 'REMARKS']
    // Documenting that no additional PDS-only columns exist in deployed UI
    expect(adminHeaders).toEqual(manningHeaders);
    expect(adminHeaders.length).toBe(7);
  });
});
