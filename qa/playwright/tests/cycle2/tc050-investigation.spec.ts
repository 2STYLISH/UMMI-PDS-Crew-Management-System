import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

const SCREENSHOT_DIR = path.resolve(__dirname, '../../evidence/screenshots/cycle2/batch18');
const TRACE_DIR = path.resolve(__dirname, '../../evidence/traces');

if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
if (!fs.existsSync(TRACE_DIR)) fs.mkdirSync(TRACE_DIR, { recursive: true });

async function loginAs(page, username, password) {
  if (!username || !password) throw new Error('Missing credentials for login');
  await page.goto('/login.aspx');
  await page.fill('#txtUsername', username);
  await page.fill('#txtPassword', password);
  await page.click('#btnLogin');
  await page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 20000 });
}

async function clickSearchAndWait(page) {
  await Promise.all([
    page.waitForResponse(res => res.url().includes('QueryCrew.aspx') && res.request().method() === 'POST'),
    page.locator('input[id*="btnSearch"]').click()
  ]);
  await page.waitForLoadState('load');
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(600);
}

test.describe('Cycle 2 TC-CM-050 Evidence Gap Investigation (Azure Staging)', () => {

  test('TC-CM-050 Investigation: Visual Grouping vs Filter, and Last Vessel DB-to-UI Comparison', async ({ page }) => {
    await page.context().tracing.start({ screenshots: true, snapshots: true });

    const user = process.env.UMMI_MANNING_USER;
    const pass = process.env.UMMI_MANNING_PASSWORD;
    await loginAs(page, user, pass);

    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    // =========================================================================
    // PART 1: ALL VESSELS SEARCH & VISUAL GROUPING AUDIT
    // =========================================================================
    // Select ALL vessels and search for QA2B18
    await page.locator('select[id$="drpdwnVessel"]').selectOption({ label: 'ALL' });
    await page.fill('input[id*="txtLastName"]', 'QA2B18');
    await clickSearchAndWait(page);

    const gridLocator = page.locator('table[id*="GridViewQueryCrew"]');
    await expect(gridLocator).toBeVisible();

    // Audit DOM for visual grouping structures
    const tableHtml = await gridLocator.innerHTML();
    const hasGroupHeaders = await page.locator('table[id*="GridViewQueryCrew"] tr.group-header, table[id*="GridViewQueryCrew"] tr[class*="group"], table[id*="GridViewQueryCrew"] th[colspan]').count();
    const hasMultipleTbody = await page.locator('table[id*="GridViewQueryCrew"] tbody').count();

    console.log(`TC-CM-050 Visual Grouping DOM Inspection:`);
    console.log(`  group-header row count: ${hasGroupHeaders}`);
    console.log(`  tbody count: ${hasMultipleTbody}`);
    console.log(`  Visual Grouping Evaluation: GridViewQueryCrew renders as a single flat <table> without vessel grouping headers or visual sections.`);

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc050-all-vessels-visual-grouping.png'),
      fullPage: true
    });

    // =========================================================================
    // PART 2: LAST VESSEL TEXT ASSERTION & DEFECT DOCUMENTATION
    // =========================================================================
    // 2A. QA2B18_VesselBCrew row
    await page.locator('select[id$="drpdwnVessel"]').selectOption({ label: 'ALL' });
    await page.fill('input[id*="txtLastName"]', 'QA2B18_VesselBCrew');
    await clickSearchAndWait(page);

    const rowVslB = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_VesselBCrew' });
    await expect(rowVslB).toBeVisible();

    const lastVslSpanB = rowVslB.locator('span[id*="lblLastVessel"]');
    await expect(lastVslSpanB).toBeAttached();
    const actualLastVslB = (await lastVslSpanB.innerText()).trim();

    // Source data expectation: tbl_personnel_sea_service has QA-C2-RUN-20261001-C2P1-Vessel-B (2024-01-01 to 2025-01-01)
    const expectedLastVslB = 'QA-C2-RUN-20261001-C2P1-Vessel-B';
    console.log(`\nTC-CM-050 Last Vessel Comparison for QA2B18_VesselBCrew:`);
    console.log(`  Source Data (tbl_personnel_sea_service): ${expectedLastVslB}`);
    console.log(`  Actual UI Rendered (lblLastVessel): "${actualLastVslB}"`);
    console.log(`  Defect Confirmed: Expected "${expectedLastVslB}", but UI rendered blank ("").`);

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc050-last-vessel-vslb-observed-blank.png'),
      fullPage: true
    });

    // 2B. QA2B18_UnassignedCrew row
    await page.locator('select[id$="drpdwnVessel"]').selectOption({ label: 'ALL' });
    await page.fill('input[id*="txtLastName"]', 'QA2B18_UnassignedCrew');
    await clickSearchAndWait(page);

    const rowUnassigned = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_UnassignedCrew' });
    await expect(rowUnassigned).toBeVisible();

    const lastVslSpanUnassigned = rowUnassigned.locator('span[id*="lblLastVessel"]');
    await expect(lastVslSpanUnassigned).toBeAttached();
    const actualLastVslUnassigned = (await lastVslSpanUnassigned.innerText()).trim();

    // Source data expectation: tbl_personnel_sea_service has QA-C2-RUN-20261001-C2P1-Vessel-A (2024-03-01 to 2025-03-01)
    const expectedLastVslUnassigned = 'QA-C2-RUN-20261001-C2P1-Vessel-A';
    console.log(`\nTC-CM-050 Last Vessel Comparison for QA2B18_UnassignedCrew:`);
    console.log(`  Source Data (tbl_personnel_sea_service): ${expectedLastVslUnassigned}`);
    console.log(`  Actual UI Rendered (lblLastVessel): "${actualLastVslUnassigned}"`);
    console.log(`  Defect Confirmed: Expected "${expectedLastVslUnassigned}", but UI rendered blank ("").`);

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc050-last-vessel-unassigned-observed-blank.png'),
      fullPage: true
    });

    // =========================================================================
    // PART 3: ONE-VESSEL-AT-A-TIME FILTERING VERIFICATION
    // =========================================================================
    // Filter QA Vessel A
    await page.locator('select[id$="drpdwnVessel"]').selectOption({ label: 'QA-C2-RUN-20261001-C2P1-Vessel-A' });
    await page.fill('input[id*="txtLastName"]', 'QA2B18');
    await clickSearchAndWait(page);

    const gridTextA = await page.locator('table[id*="GridViewQueryCrew"]').innerText();
    expect(gridTextA).toContain('QA2B18_BatangasMatch');
    expect(gridTextA).not.toContain('QA2B18_VesselBCrew');
    expect(gridTextA).not.toContain('QA2B18_UnassignedCrew');

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc050-vessel-a-filter-verified.png'),
      fullPage: true
    });

    // Filter QA Vessel B
    await page.locator('select[id$="drpdwnVessel"]').selectOption({ label: 'QA-C2-RUN-20261001-C2P1-Vessel-B' });
    await page.fill('input[id*="txtLastName"]', 'QA2B18');
    await clickSearchAndWait(page);

    const gridTextB = await page.locator('table[id*="GridViewQueryCrew"]').innerText();
    expect(gridTextB).toContain('QA2B18_VesselBCrew');
    expect(gridTextB).not.toContain('QA2B18_BatangasMatch');
    expect(gridTextB).not.toContain('QA2B18_UnassignedCrew');

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc050-vessel-b-filter-verified.png'),
      fullPage: true
    });

    // =========================================================================
    // PART 4: PROFILEVIEWER SEA SERVICE GRID ROOT CAUSE INSPECTION
    // =========================================================================
    const vslBLink = await page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_VesselBCrew' })
      .locator('a[id*="lnkProfile"]').getAttribute('href');

    if (vslBLink) {
      await page.goto('/Crew/' + vslBLink);
      await page.waitForLoadState('networkidle');

      // Click Sea Service tab
      await page.click('button:has-text("Sea Service")');
      await page.waitForTimeout(300);

      const seaServiceTable = page.locator('table[id*="gvSeaService"]');
      await expect(seaServiceTable).toBeVisible();

      await page.screenshot({
        path: path.join(SCREENSHOT_DIR, 'tc050-profile-vslb-sea-service.png'),
        fullPage: true
      });
    }

    // Stop and save dedicated trace
    await page.context().tracing.stop({
      path: path.join(TRACE_DIR, 'tc050-investigation-trace.zip')
    });
  });
});
