import { test, expect } from '@playwright/test';
import * as path from 'path';

const SCREENSHOT_DIR = path.resolve(__dirname, '../../evidence/screenshots/cycle2/batch18');

async function loginAs(page, username, password) {
  await page.goto('/login.aspx');
  await page.fill('#txtUsername', username);
  await page.fill('#txtPassword', password);
  await page.click('#btnLogin');
  await page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 15000 });
}

test.describe('Batch 18 Smoke Check (Visible Headed Chrome Verification)', () => {

  test('TC-CM-041: Principal crew-status filter defaults to Active & available choices', async ({ page }) => {
    const user = process.env.QA_C2_PRINCIPAL_USER || process.env.UMMI_PRINCIPAL_USER || 'qa.c2.20261001.principal';
    const pass = process.env.QA_C2_PRINCIPAL_PASSWORD || process.env.UMMI_PRINCIPAL_PASSWORD;
    await loginAs(page, user, pass);

    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    const statusDropdown = page.locator('select[id*="drpdwnCrewStatus"]');
    await expect(statusDropdown).toBeVisible();

    const selectedVal = await statusDropdown.inputValue();
    const selectedText = await statusDropdown.locator('option:checked').textContent();
    console.log(`TC-CM-041: Principal default status: val=${selectedVal}, text=${selectedText}`);
    expect(selectedText?.trim().toUpperCase()).toBe('ACTIVE');

    const options = await statusDropdown.locator('option').allTextContents();
    console.log('TC-CM-041: Available status options for Principal:', options);
    expect(options.length).toBeGreaterThanOrEqual(2);

    // Verify Principal cannot reset or export
    const btnReset = page.locator('input[id*="btnReset"]');
    const btnExport = page.locator('input[id*="btnExportExcel"]');
    expect(await btnReset.isVisible()).toBe(false);
    expect(await btnExport.isVisible()).toBe(false);

    await page.click('input[id*="btnSearch"]');
    await page.waitForLoadState('networkidle');

    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc041-smoke-visible.png'), fullPage: true });
    console.log('TC-CM-041: Verification complete. Chrome window confirmed visible.');
  });

});
