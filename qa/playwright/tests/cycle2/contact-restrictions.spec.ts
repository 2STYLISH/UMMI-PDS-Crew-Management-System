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

test.describe.serial('Cycle 2 Contact Restrictions Test Suite (Azure Staging)', () => {

  // ==========================================================================
  // TC-CM-067: Documentation Officer with viewcrewcontactdetails = 0
  // ==========================================================================
  test('TC-CM-067: Documentation Officer (viewcrewcontactdetails=0) - Contact & Statutory details hidden, non-sensitive profile loads', async ({ page }) => {
    const user = process.env.QA2CONTACT_DOC_USER || 'qa2contact.doc.restricted';
    const pass = process.env.QA2CONTACT_DOC_PASSWORD;

    await page.context().tracing.start({ screenshots: true, snapshots: true });

    await loginAs(page, user, pass);

    // Open crew search
    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    // Query controlled QA2B18 crew record
    await page.fill('input[id*="txtLastName"]', 'QA2B18_BatangasMatch');
    await clickSearchAndWait(page);

    const crewRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BatangasMatch' });
    await expect(crewRow).toBeVisible();

    // Click normal encrypted profile link and await popup window
    const profileLink = crewRow.locator('a[id*="lnkProfile"]');
    await expect(profileLink).toBeVisible();

    const [profilePage] = await Promise.all([
      page.context().waitForEvent('page'),
      profileLink.click()
    ]);
    await profilePage.waitForLoadState('networkidle');

    // 1. Assert Contact Details section is completely HIDDEN
    const contactInfo = profilePage.locator('#divContactInfo, div[id$="divContactInfo"]');
    await expect(contactInfo).toHaveCount(0);

    // 2. Assert Statutory Details section is completely HIDDEN
    const statutoryInfo = profilePage.locator('#divStatutory, div[id$="divStatutory"]');
    await expect(statutoryInfo).toHaveCount(0);

    // 3. Assert Personal Notes section is completely HIDDEN
    const personalNotes = profilePage.locator('#divPersonalNotes, div[id$="divPersonalNotes"]');
    await expect(personalNotes).toHaveCount(0);

    // 4. Assert permitted non-sensitive profile content loads cleanly
    const fullNameLabel = profilePage.locator('span[id*="lblFullName"]');
    await expect(fullNameLabel).toBeVisible();
    await expect(fullNameLabel).toContainText('QA2B18_BatangasMatch');

    const rankLabel = profilePage.locator('span[id*="lblRank"]');
    await expect(rankLabel).toBeVisible();
    await expect(rankLabel).toHaveText('AB SEAMAN');

    const basicInfoCard = profilePage.locator('.card-header-ummi:has-text("Basic Information")');
    await expect(basicInfoCard).toBeVisible();

    await profilePage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc067-doc-officer-contact-hidden.png'),
      fullPage: true
    });

    await page.context().tracing.stop({
      path: path.join(TRACE_DIR, 'tc067-trace.zip')
    });

    await profilePage.close();
  });

  // ==========================================================================
  // TC-CM-069: Admin with viewcrewcontactdetails = 0
  // ==========================================================================
  test('TC-CM-069: Admin (viewcrewcontactdetails=0) - Contact & Statutory details hidden, non-sensitive profile loads', async ({ page }) => {
    const user = process.env.QA2CONTACT_ADMIN_USER || 'qa2contact.admin.restricted';
    const pass = process.env.QA2CONTACT_ADMIN_PASSWORD;

    await page.context().tracing.start({ screenshots: true, snapshots: true });

    await loginAs(page, user, pass);

    // Open crew search
    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    // Query controlled QA2B18 crew record
    await page.fill('input[id*="txtLastName"]', 'QA2B18_BatangasMatch');
    await clickSearchAndWait(page);

    const crewRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BatangasMatch' });
    await expect(crewRow).toBeVisible();

    // Click normal encrypted profile link and await popup window
    const profileLink = crewRow.locator('a[id*="lnkProfile"]');
    await expect(profileLink).toBeVisible();

    const [profilePage] = await Promise.all([
      page.context().waitForEvent('page'),
      profileLink.click()
    ]);
    await profilePage.waitForLoadState('networkidle');

    // 1. Assert Contact Details section is completely HIDDEN
    const contactInfo = profilePage.locator('#divContactInfo, div[id$="divContactInfo"]');
    await expect(contactInfo).toHaveCount(0);

    // 2. Assert Statutory Details section is completely HIDDEN
    const statutoryInfo = profilePage.locator('#divStatutory, div[id$="divStatutory"]');
    await expect(statutoryInfo).toHaveCount(0);

    // 3. Assert Personal Notes section is completely HIDDEN
    const personalNotes = profilePage.locator('#divPersonalNotes, div[id$="divPersonalNotes"]');
    await expect(personalNotes).toHaveCount(0);

    // 4. Assert permitted non-sensitive profile content loads cleanly
    const fullNameLabel = profilePage.locator('span[id*="lblFullName"]');
    await expect(fullNameLabel).toBeVisible();
    await expect(fullNameLabel).toContainText('QA2B18_BatangasMatch');

    const rankLabel = profilePage.locator('span[id*="lblRank"]');
    await expect(rankLabel).toBeVisible();
    await expect(rankLabel).toHaveText('AB SEAMAN');

    const basicInfoCard = profilePage.locator('.card-header-ummi:has-text("Basic Information")');
    await expect(basicInfoCard).toBeVisible();

    await profilePage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc069-admin-contact-hidden.png'),
      fullPage: true
    });

    await page.context().tracing.stop({
      path: path.join(TRACE_DIR, 'tc069-trace.zip')
    });

    await profilePage.close();
  });

  // ==========================================================================
  // TC-CM-071: Super-Admin with viewcrewcontactdetails = 0
  // ==========================================================================
  test('TC-CM-071: Super-Admin (viewcrewcontactdetails=0) - Contact & Statutory details hidden, non-sensitive profile loads', async ({ page }) => {
    const user = process.env.QA2CONTACT_SUPERADMIN_USER || 'qa2contact.superadmin.restricted';
    const pass = process.env.QA2CONTACT_SUPERADMIN_PASSWORD;

    await page.context().tracing.start({ screenshots: true, snapshots: true });

    await loginAs(page, user, pass);

    // Open crew search
    await page.goto('/Crew/QueryCrew.aspx');
    await page.waitForLoadState('networkidle');

    // Query controlled QA2B18 crew record
    await page.fill('input[id*="txtLastName"]', 'QA2B18_BatangasMatch');
    await clickSearchAndWait(page);

    const crewRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BatangasMatch' });
    await expect(crewRow).toBeVisible();

    // Click normal encrypted profile link and await popup window
    const profileLink = crewRow.locator('a[id*="lnkProfile"]');
    await expect(profileLink).toBeVisible();

    const [profilePage] = await Promise.all([
      page.context().waitForEvent('page'),
      profileLink.click()
    ]);
    await profilePage.waitForLoadState('networkidle');

    // 1. Assert Contact Details section is completely HIDDEN
    const contactInfo = profilePage.locator('#divContactInfo, div[id$="divContactInfo"]');
    await expect(contactInfo).toHaveCount(0);

    // 2. Assert Statutory Details section is completely HIDDEN
    const statutoryInfo = profilePage.locator('#divStatutory, div[id$="divStatutory"]');
    await expect(statutoryInfo).toHaveCount(0);

    // 3. Assert Personal Notes section is completely HIDDEN
    const personalNotes = profilePage.locator('#divPersonalNotes, div[id$="divPersonalNotes"]');
    await expect(personalNotes).toHaveCount(0);

    // 4. Assert permitted non-sensitive profile content loads cleanly
    const fullNameLabel = profilePage.locator('span[id*="lblFullName"]');
    await expect(fullNameLabel).toBeVisible();
    await expect(fullNameLabel).toContainText('QA2B18_BatangasMatch');

    const rankLabel = profilePage.locator('span[id*="lblRank"]');
    await expect(rankLabel).toBeVisible();
    await expect(rankLabel).toHaveText('AB SEAMAN');

    const basicInfoCard = profilePage.locator('.card-header-ummi:has-text("Basic Information")');
    await expect(basicInfoCard).toBeVisible();

    await profilePage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc071-superadmin-contact-hidden.png'),
      fullPage: true
    });

    await page.context().tracing.stop({
      path: path.join(TRACE_DIR, 'tc071-trace.zip')
    });

    await profilePage.close();
  });
});
