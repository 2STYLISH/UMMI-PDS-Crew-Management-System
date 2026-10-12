import { test, expect } from '@playwright/test';
import * as path from 'path';

function sanitizeUrl(rawUrl: string): string {
  return rawUrl.replace(/([?&]e=)[^&]+/gi, '$1[REDACTED]').replace(/([?&]token=)[^&]+/gi, '$1[REDACTED]');
}

test('Inspect existing applicant links on staging', async ({ page }) => {
  const user = process.env.QA_MANNING_CONTROL_USER || process.env.UMMI_MANNING_USER;
  const pass = process.env.QA_MANNING_CONTROL_PASSWORD || process.env.UMMI_MANNING_PASSWORD;

  if (!user || !pass) {
    throw new Error('Manning credentials not found in environment.');
  }

  // Check server Date header
  const initialResp = await page.goto('/login.aspx');
  const serverDateHeader = initialResp?.headers()['date'];
  console.log('Staging Server HTTP Date Header:', serverDateHeader);

  await page.fill('#txtUsername', user);
  await page.fill('#txtPassword', pass);
  await page.click('#btnLogin');
  await page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 15000 });

  await page.goto('/Applicant/ApplicantPool.aspx');
  await page.waitForLoadState('networkidle');

  await page.click('input[id*="btnManageLinks"]');
  await page.waitForLoadState('networkidle');

  const linksGrid = page.locator('table[id*="gvLinks"]');
  await expect(linksGrid).toBeVisible();

  const rows = linksGrid.locator('tr');
  const rowCount = await rows.count();
  console.log(`Total rows in gvLinks: ${rowCount}`);

  const linksData: any[] = [];
  for (let i = 1; i < rowCount; i++) {
    const row = rows.nth(i);
    const cells = row.locator('td');
    const cellCount = await cells.count();
    if (cellCount >= 5) {
      const name = (await cells.nth(0).innerText()).trim();
      const email = (await cells.nth(1).innerText()).trim();
      const pos = (await cells.nth(2).innerText()).trim();
      const validity = (await cells.nth(3).innerText()).trim();
      const status = (await cells.nth(4).innerText()).trim();

      const copyBtn = row.locator('button.copy-btn[onclick*="login.aspx?e="]');
      const hasCopy = await copyBtn.isVisible().catch(() => false);
      let hasUrl = false;
      if (hasCopy) {
        hasUrl = true;
      }
      linksData.push({ index: i, name, email, pos, validity, status, hasUrl });
    }
  }

  console.log('Captured links summary (first 20):');
  console.log(JSON.stringify(linksData.slice(0, 20), null, 2));
  console.log(`Total captured links: ${linksData.length}`);

  // Count by status
  const statusCounts = linksData.reduce((acc, l) => {
    acc[l.status] = (acc[l.status] || 0) + 1;
    return acc;
  }, {});
  console.log('Status counts:', JSON.stringify(statusCounts));
});
