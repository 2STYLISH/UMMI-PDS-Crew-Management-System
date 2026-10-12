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

test.describe('Profile BMI and HMO Verification', () => {

  test('TC-CM-076: BMI = kilograms / (meters squared), displayed rounded to one decimal', async ({ page }) => {
    const user = process.env.UMMI_MANNING_USER;
    const pass = process.env.UMMI_MANNING_PASSWORD;
    await loginAs(page, user, pass);

    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    await page.fill('input[id*="txtLastName"]', 'Santos');
    await page.click('input[id*="btnSearch"]');
    await page.waitForLoadState('networkidle');

    const profileLink = page.locator('a[href*="ProfileViewer.aspx"]').first();
    await expect(profileLink).toBeVisible();
    const targetUrl = await profileLink.getAttribute('href');
    const fullUrl = new URL(targetUrl!, page.url()).href;
    console.log('Navigating to full profile URL:', fullUrl);

    await page.goto(fullUrl);
    await page.waitForLoadState('networkidle');

    const lblHeight = await page.locator('span[id*="lblHeight"], [id$="lblHeight"]').textContent();
    const lblWeight = await page.locator('span[id*="lblWeight"], [id$="lblWeight"]').textContent();
    const lblBMI = await page.locator('span[id*="lblBMI"], [id$="lblBMI"]').textContent();
    const lblBMIClass = await page.locator('span[id*="lblBMIClass"], [id$="lblBMIClass"]').textContent();

    console.log(`TC-CM-076: Observed Height=${lblHeight}, Weight=${lblWeight}, BMI=${lblBMI}, Class=${lblBMIClass}`);
    expect(lblBMI?.trim()).toBe('22.2');
    expect(lblBMIClass?.trim()).toBe('Normal');

    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc076-bmi-calculation-rounded.png') });
  });

  test('TC-CM-082: HMO is informational profile data; Copy exists for statutory IDs but not HMO', async ({ page }) => {
    const user = process.env.UMMI_MANNING_USER;
    const pass = process.env.UMMI_MANNING_PASSWORD;
    await loginAs(page, user, pass);

    await page.goto('/Crew/QueryCrew.aspx');
    await page.fill('input[id*="txtLastName"]', 'Santos');
    await page.click('input[id*="btnSearch"]');
    await page.waitForLoadState('networkidle');

    const profileLink = page.locator('a[href*="ProfileViewer.aspx"]').first();
    const targetUrl = await profileLink.getAttribute('href');
    const fullUrl = new URL(targetUrl!, page.url()).href;

    await page.goto(fullUrl);
    await page.waitForLoadState('networkidle');

    const lblHMONumber = page.locator('span[id*="lblHMONumber"], [id$="lblHMONumber"]');
    await expect(lblHMONumber).toBeVisible();
    const hmoVal = await lblHMONumber.textContent();
    console.log('TC-CM-082: HMO Number displayed:', hmoVal);

    const sssCopy = page.locator('button.copy-btn[onclick*="lblSSS"]');
    const tinCopy = page.locator('button.copy-btn[onclick*="lblTIN"]');
    const philCopy = page.locator('button.copy-btn[onclick*="lblPhilHealth"]');
    const pagCopy = page.locator('button.copy-btn[onclick*="lblPagIBIG"]');

    await expect(sssCopy).toBeVisible();
    await expect(tinCopy).toBeVisible();
    await expect(philCopy).toBeVisible();
    await expect(pagCopy).toBeVisible();

    const hmoCopy = page.locator('button.copy-btn[onclick*="lblHMO"]');
    const hmoCopyCount = await hmoCopy.count();
    console.log('TC-CM-082: HMO copy buttons count:', hmoCopyCount);
    expect(hmoCopyCount).toBe(0);

    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc082-hmo-display-no-copy.png') });
  });

});
