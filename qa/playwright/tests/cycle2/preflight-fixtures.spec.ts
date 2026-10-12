import { test } from '@playwright/test';
import * as path from 'path';

test('Comprehensive read-only preflight inspection of Azure staging', async ({ page }) => {
  const user = process.env.UMMI_MANNING_USER || 'demo.manning';
  const pass = process.env.UMMI_MANNING_PASSWORD || '';
  await page.goto('/login.aspx');
  await page.fill('#txtUsername', user);
  await page.fill('#txtPassword', pass);
  await page.click('#btnLogin');
  await page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 15000 });

  console.log('=== 1. INSPECTING CREW GRID AND PROFILE VIEWER ===');
  await page.goto('/Crew/QueryCrew.aspx');
  await page.waitForLoadState('networkidle');

  // Grab the first 5 crew profile links from the grid
  const crewLinks = page.locator('table[id*="GridViewQueryCrew"] a.gv-link');
  const crewCount = await crewLinks.count();
  console.log(`Found ${crewCount} crew links on Page 1.`);

  for (let i = 0; i < Math.min(crewCount, 3); i++) {
    const link = crewLinks.nth(i);
    const crewName = await link.textContent();
    const href = await link.getAttribute('href');
    console.log(`Crew ${i + 1}: Name="${crewName?.trim()}", Href="${href?.substring(0, 50)}..."`);
  }

  // Open the first profile
  if (crewCount > 0) {
    const firstHref = await crewLinks.first().getAttribute('href');
    const fullProfileUrl = new URL(firstHref!, page.url()).href;
    console.log('Navigating to first crew ProfileViewer via encrypted link...');
    await page.goto(fullProfileUrl);
    await page.waitForLoadState('networkidle');
    console.log('Landed at URL:', page.url());

    const h = await page.locator('span[id$="lblHeight"]').textContent().catch(() => 'N/A');
    const w = await page.locator('span[id$="lblWeight"]').textContent().catch(() => 'N/A');
    const bmi = await page.locator('span[id$="lblBMI"]').textContent().catch(() => 'N/A');
    const bmiClass = await page.locator('span[id$="lblBMIClass"]').textContent().catch(() => 'N/A');
    const hmo = await page.locator('span[id$="lblHMONumber"]').textContent().catch(() => 'N/A');
    console.log(`Profile 1 Biometrics: Height=${h}, Weight=${w}, BMI=${bmi}, Class=${bmiClass}, HMO=${hmo}`);

    // Check all doc tables
    const docTables = page.locator('table.ummi-table, table[id*="gvDoc"]');
    const docCount = await docTables.count();
    console.log(`Document tables on profile: ${docCount}`);
    for (let t = 0; t < docCount; t++) {
      const tableId = await docTables.nth(t).getAttribute('id');
      const rowCount = await docTables.nth(t).locator('tr').count() - 1;
      console.log(`Table #${t} (ID=${tableId}): ${rowCount} document rows`);
    }
  }

  console.log('=== 2. INSPECTING MANAGE LINKS DATASET ===');
  await page.goto('/Applicant/ApplicantPool.aspx');
  await page.waitForLoadState('networkidle');
  await page.click('input[id*="btnManageLinks"]');
  await page.waitForLoadState('networkidle');

  const linksGrid = page.locator('table[id*="gvLinks"]');
  const visibleLinks = await linksGrid.locator('tr').count() - 1;
  console.log(`Manage Links visible rows: ${visibleLinks}`);

  // Check pager or hidden field for total links count
  const pagerLinks = page.locator('div[id*="panelManageLinks"] .pagination, div[id*="panelManageLinks"] .pager');
  const pagerCount = await pagerLinks.count();
  console.log(`Manage Links pager count: ${pagerCount}`);

  // Sample the first and last visible link timestamps in Column 4 (GENERATED)
  if (visibleLinks > 0) {
    const firstDate = await linksGrid.locator('tr:nth-child(2) td:nth-child(4)').textContent();
    const lastDate = await linksGrid.locator(`tr:nth-child(${visibleLinks + 1}) td:nth-child(4)`).textContent();
    console.log(`First visible link generated: ${firstDate?.trim()}, Last visible link: ${lastDate?.trim()}`);

    // Count statuses across the 50 visible rows
    const statusCells = await linksGrid.locator('tr td:nth-child(6)').allTextContents();
    const counts = statusCells.reduce((acc, s) => {
      const trimmed = s.trim();
      acc[trimmed] = (acc[trimmed] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);
    console.log('Visible link status breakdown:', counts);
  }

  console.log('=== 3. SEARCHING FOR A001 IN DATABASE VIA APPLICANT AND CREW ===');
  await page.goto('/Crew/QueryCrew.aspx');
  await page.waitForLoadState('networkidle');
  // Check if any crew has rank AB SEAMAN and height 180
  await page.selectOption('select[id*="drpdwnRank"]', { label: 'AB SEAMAN' }).catch(() => console.log('AB SEAMAN not in dropdown'));
  await page.click('input[id*="btnSearch"]');
  await page.waitForLoadState('networkidle');
  const abCount = await page.locator('span[id*="lblCrewCount"]').textContent();
  console.log('Crew with Rank AB SEAMAN count =', abCount);
});
