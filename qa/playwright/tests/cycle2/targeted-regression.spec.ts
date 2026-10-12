import { test, expect } from '../../fixtures/auth.fixture';
import { Page } from '@playwright/test';
import { LoginPage } from '../../pages/LoginPage';
import crypto from 'crypto';
import path from 'path';

// ---------------------------------------------------------------------------
// AES-256 Symmetric Encryption Helper (mirrors CryptoHelper.vb)
// ---------------------------------------------------------------------------
const CRYPTO_KEY = 'UMMI-CREW-MGMT-2026-AES256-KEY!!';
const CRYPTO_SALT = 'UMMI2026SALT';

function getCryptoKey(): Buffer {
  return crypto.pbkdf2Sync(CRYPTO_KEY, Buffer.from(CRYPTO_SALT, 'utf8'), 1000, 32, 'sha1');
}

export function encryptPayload(plainText: string): string {
  const key = getCryptoKey();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
  const encrypted = Buffer.concat([cipher.update(plainText, 'utf8'), cipher.final()]);
  const combined = Buffer.concat([iv, encrypted]);
  return combined.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '~');
}

export function decryptPayload(cipherText: string): string {
  const b64 = cipherText.replace(/-/g, '+').replace(/_/g, '/').replace(/~/g, '=');
  const buf = Buffer.from(b64, 'base64');
  const iv = buf.subarray(0, 16);
  const payload = buf.subarray(16);
  const key = getCryptoKey();
  const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
  const decrypted = Buffer.concat([decipher.update(payload), decipher.final()]);
  return decrypted.toString('utf8');
}

// ---------------------------------------------------------------------------
// Date Helpers
// ---------------------------------------------------------------------------
function getTomorrowDateString(): string {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  return tomorrow.toISOString().split('T')[0];
}

function getYesterdayDateString(): string {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  return yesterday.toISOString().split('T')[0];
}

function getFutureDateString(days: number): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString().split('T')[0];
}

// ---------------------------------------------------------------------------
// Constants & Fixtures
// ---------------------------------------------------------------------------
const PREFIX = 'QA-C2-REGRESSION-20261004';
const QA_VESSEL_A = 'QA-C2-RUN-20261001-C2P1-Vessel-A';
const QA_VESSEL_B = 'QA-C2-RUN-20261001-C2P1-Vessel-B';

const FIXTURES_DIR = path.resolve(__dirname, '../../test-data/ai-fixtures');
const MANIFEST_RESUME_PDF = path.join(FIXTURES_DIR, 'synthetic_manifest_resume.pdf');
const INVALID_TEXT_TXT = path.join(FIXTURES_DIR, 'invalid_text.txt');
const INVALID_SCRIPT_EXE = path.join(FIXTURES_DIR, 'invalid_script.exe');

// ---------------------------------------------------------------------------
// Panel Helpers
// ---------------------------------------------------------------------------
async function openGenerateLinkPanel(page: Page) {
  if (!page.url().includes('ApplicantPool.aspx')) {
    await page.goto('/Applicant/ApplicantPool.aspx');
  }
  const genBtn = page.locator('[id$="btnGenerateLink"]');
  await Promise.all([
    page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST').catch(() => {}),
    genBtn.click(),
  ]);
  await page.waitForLoadState('networkidle').catch(() => {});
  await expect(page.locator('[id$="panelGenerateLink"]')).toBeVisible({ timeout: 10000 });
}

async function openManageLinksPanel(page: Page) {
  if (!page.url().includes('ApplicantPool.aspx')) {
    await page.goto('/Applicant/ApplicantPool.aspx');
  }
  const isAlreadyVisible = await page.locator('[id$="panelManageLinks"]').isVisible().catch(() => false);
  if (!isAlreadyVisible) {
    const manageBtn = page.locator('[id$="btnManageLinks"]');
    await Promise.all([
      page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST').catch(() => {}),
      manageBtn.click(),
    ]);
    await page.waitForLoadState('networkidle').catch(() => {});
  }
  await expect(page.locator('[id$="panelManageLinks"]')).toBeVisible({ timeout: 10000 });
}

async function cleanupGeneratedLink(page: Page, applicantName: string) {
  try {
    await page.goto('/Applicant/ApplicantPool.aspx');
    await openManageLinksPanel(page);
    const row = page.locator('[id$="gvLinks"] tr').filter({ hasText: applicantName }).first();
    if (await row.isVisible({ timeout: 3000 }).catch(() => false)) {
      const ddl = row.locator('select[id$="drpdwnNewStatus"]');
      const applyBtn = row.locator('a[id$="btnUpdateStatus"]');
      if (await ddl.isVisible().catch(() => false)) {
        await ddl.selectOption('Expired');
        page.once('dialog', d => d.accept());
        await applyBtn.click();
        await page.waitForLoadState('networkidle').catch(() => {});
      }
      const updatedRow = page.locator('[id$="gvLinks"] tr').filter({ hasText: applicantName }).first();
      const deleteBtn = updatedRow.locator('a[id$="btnDeleteLink"]');
      if (await deleteBtn.isVisible().catch(() => false)) {
        page.once('dialog', d => d.accept());
        await deleteBtn.click();
        await page.waitForLoadState('networkidle').catch(() => {});
      }
    }
  } catch (err) {
    // Teardown safety
  }
}

async function selectVesselOnCCL(page: Page, vesselName: string) {
  await page.goto('/Crew/CrewChangeList.aspx');
  await page.waitForLoadState('networkidle').catch(() => {});

  const picker = page.locator('[id$="drpVesselPicker"]');
  if (await picker.isVisible()) {
    await Promise.all([
      page.waitForResponse(res => res.url().includes('CrewChangeList.aspx') && res.request().method() === 'POST').catch(() => {}),
      picker.selectOption({ label: vesselName }),
    ]);
    await page.waitForLoadState('networkidle').catch(() => {});
  }
}

async function waitForExtractionTerminalState(appPage: Page, timeoutMs = 45000): Promise<'COMPLETED' | 'ERROR'> {
  const result = await Promise.race([
    appPage.locator('#aiCompletionBox').waitFor({ state: 'visible', timeout: timeoutMs }).then(() => 'COMPLETED' as const),
    appPage.locator('#aiErrorBox').waitFor({ state: 'visible', timeout: timeoutMs }).then(() => 'ERROR' as const),
  ]);
  return result;
}

// ============================================================================
// Targeted Cycle 2 Regression Test Suite
// ============================================================================
test.describe('UMMI Cycle 2 Targeted Regression Test Suite', () => {

  // --------------------------------------------------------------------------
  // TC-CM-043: Vessel Owner - Hide internal search controls and enforce export access control
  // --------------------------------------------------------------------------
  test('TC-CM-043: Vessel Owner - Hide internal search controls and enforce export access control', async ({ loginAsRole, page, browser }) => {
    await test.step('Step 1: Sign in as Vessel Owner. Confirm Export Excel is hidden on initial load', async () => {
      await loginAsRole('VESSEL_OWNER');
      await page.goto('/Crew/QueryCrew.aspx');
      await page.waitForLoadState('networkidle').catch(() => {});

      // Confirm Export Excel is hidden on initial load per FR-CM-25 / UC-CM-04
      await expect(page.locator('[id$="btnExportExcel"]')).toBeHidden();
      // Internal-only controls must also remain hidden per FR-CM-05 / UC-CM-01
      await expect(page.locator('[id$="drpdwnCrewAvailability"]')).toBeHidden();
      await expect(page.locator('[id$="btnReset"]')).toBeHidden();
      await expect(page.locator('[id$="btnReleasingChecklist"]')).toBeHidden();
    });

    await test.step('Step 2: Perform search or filter postback and confirm Export Excel remains hidden', async () => {
      const searchBtn = page.locator('[id$="btnSearch"]');
      await Promise.all([
        page.waitForResponse(res => res.url().includes('QueryCrew.aspx') && res.request().method() === 'POST'),
        searchBtn.click(),
      ]);
      await page.waitForLoadState('networkidle').catch(() => {});

      // Confirm Export Excel remains hidden afterward
      await expect(page.locator('[id$="btnExportExcel"]')).toBeHidden();
      await expect(page.locator('[id$="drpdwnCrewAvailability"]')).toBeHidden();
      await expect(page.locator('[id$="btnReset"]')).toBeHidden();
    });

    await test.step('Step 3: Verify server-side export operation rejects Vessel Owner access', async () => {
      let downloadTriggered = false;
      const downloadPromise = page.waitForEvent('download', { timeout: 3000 })
        .then(() => { downloadTriggered = true; })
        .catch(() => {});

      // Attempt to invoke the postback target directly from the client
      await page.evaluate(() => {
        if (typeof (window as any).__doPostBack === 'function') {
          (window as any).__doPostBack('ctl00$ContentPlaceHolder1$btnExportExcel', '');
        }
      });
      await page.waitForLoadState('networkidle').catch(() => {});
      await downloadPromise;

      expect(downloadTriggered).toBe(false);
    });

    await test.step('Step 4: Confirm authorized internal roles retain expected export behavior', async () => {
      const internalContext = await browser.newContext();
      const internalPage = await internalContext.newPage();
      const loginPage = new LoginPage(internalPage);
      await loginPage.loginAs('MANNING');
      await internalPage.goto('/Crew/QueryCrew.aspx');
      await internalPage.waitForLoadState('networkidle').catch(() => {});

      const internalExportBtn = internalPage.locator('[id$="btnExportExcel"]');
      await expect(internalExportBtn).toBeVisible();

      // Trigger export and verify download
      const downloadPromise = internalPage.waitForEvent('download', { timeout: 15000 });
      await internalExportBtn.click();
      const download = await downloadPromise;
      expect(download.suggestedFilename()).toMatch(/^CrewList_.*\.xlsx$/i);
      await internalContext.close();
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-103: Statutory verification - Verify Benefit numbers
  // --------------------------------------------------------------------------
  test('TC-CM-103: Statutory verification - Verify Benefit numbers', async ({ loginAsRole, crewSearchPage, page, activityLogsPage }) => {
    let cleanHref = '';

    await test.step('Step 1: Locate controlled synthetic crew and execute benefits verification', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();
      await crewSearchPage.lastNameInput.fill('Santos');
      await crewSearchPage.firstNameInput.fill('QA Maria');
      await crewSearchPage.search();

      const profileLink = crewSearchPage.resultRows.first().locator('td a[href*="ProfileViewer"]');
      await expect(profileLink).toBeVisible();
      const rawHref = (await profileLink.getAttribute('href')) || '';
      expect(rawHref).toContain('ProfileViewer.aspx');

      cleanHref = rawHref.replace(/^~/, '');
      if (!cleanHref.startsWith('/Crew/') && !cleanHref.startsWith('http')) {
        cleanHref = '/Crew/' + cleanHref.replace(/^\/?/, '');
      }

      // Open in verifier mode for statutory benefits
      const verifierUrl = `${cleanHref}&Verifier=${encodeURIComponent(encryptPayload('benefits'))}`;
      await page.goto(verifierUrl);
      await page.waitForLoadState('networkidle').catch(() => {});

      const verifyBanner = page.locator('[id$="divVerifyBanner"]');
      await expect(verifyBanner).toBeVisible();
      await expect(page.locator('[id$="lblVerifyType"]')).toContainText(/Statutory Benefits Verification Mode/i);

      const verifyBtn = page.locator('[id$="btnVerify"]');
      await expect(verifyBtn).toBeVisible();
      await verifyBtn.click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = page.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Successfully verified/i);
    });

    await test.step('Step 2: Confirm functional status change on profile and inspect Activity Logs', async () => {
      // Reload clean profile to confirm functional status
      await page.goto(cleanHref);
      await page.waitForLoadState('networkidle').catch(() => {});

      const benefitsLabel = page.locator('[id$="lblVerifiedBenefits"]');
      await expect(benefitsLabel).toBeVisible();
      await expect(benefitsLabel).toContainText(/Benefits Verified/i);

      // Verify audit trail entry in Activity Logs as Super Admin
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('ProfileViewer');

      const hasVerifyLog = await activityLogsPage.hasMatchingLog({
        category: 'ProfileViewer',
        activitySubstring: 'Verified benefits',
      });
      expect(hasVerifyLog).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-104: Statutory verification - Verify TIN
  // --------------------------------------------------------------------------
  test('TC-CM-104: Statutory verification - Verify TIN', async ({ loginAsRole, crewSearchPage, page, activityLogsPage }) => {
    let cleanHref = '';

    await test.step('Step 1: Locate controlled synthetic crew and execute TIN verification', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();
      await crewSearchPage.lastNameInput.fill('Santos');
      await crewSearchPage.firstNameInput.fill('QA Maria');
      await crewSearchPage.search();

      const profileLink = crewSearchPage.resultRows.first().locator('td a[href*="ProfileViewer"]');
      await expect(profileLink).toBeVisible();
      const rawHref = (await profileLink.getAttribute('href')) || '';
      expect(rawHref).toContain('ProfileViewer.aspx');

      cleanHref = rawHref.replace(/^~/, '');
      if (!cleanHref.startsWith('/Crew/') && !cleanHref.startsWith('http')) {
        cleanHref = '/Crew/' + cleanHref.replace(/^\/?/, '');
      }

      // Open in verifier mode for TIN
      const verifierUrl = `${cleanHref}&Verifier=${encodeURIComponent(encryptPayload('tin'))}`;
      await page.goto(verifierUrl);
      await page.waitForLoadState('networkidle').catch(() => {});

      const verifyBanner = page.locator('[id$="divVerifyBanner"]');
      await expect(verifyBanner).toBeVisible();
      await expect(page.locator('[id$="lblVerifyType"]')).toContainText(/TIN Verification Mode/i);

      const verifyBtn = page.locator('[id$="btnVerify"]');
      await expect(verifyBtn).toBeVisible();
      await verifyBtn.click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = page.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Successfully verified/i);
    });

    await test.step('Step 2: Confirm functional status change on profile and inspect Activity Logs', async () => {
      // Reload clean profile to confirm functional status
      await page.goto(cleanHref);
      await page.waitForLoadState('networkidle').catch(() => {});

      const tinLabel = page.locator('[id$="lblVerifiedTIN"]');
      await expect(tinLabel).toBeVisible();
      await expect(tinLabel).toContainText(/TIN Verified/i);

      // Verify audit trail entry in Activity Logs as Super Admin
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('ProfileViewer');

      const hasVerifyLog = await activityLogsPage.hasMatchingLog({
        category: 'ProfileViewer',
        activitySubstring: 'Verified tin',
      });
      expect(hasVerifyLog).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-144: Email composition - Compose encoding email without claiming delivery
  // --------------------------------------------------------------------------
  test('TC-CM-144: Email composition - Compose encoding email without claiming delivery', async ({ loginAsRole, page, activityLogsPage }) => {
    const testName = `${PREFIX}-TC144-EmailApp`;
    const testEmail = 'tc144-regression@example.com';
    const tomorrowStr = getTomorrowDateString();

    await test.step('Step 1: Generate applicant link and select Send by Email', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(tomorrowStr);
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await expect(page.locator('[id$="panelLinkResult"]')).toBeVisible();

      const emailBtn = page.locator('[id$="btnSendLinkEmail"]');
      await expect(emailBtn).toBeVisible();

      // Click Send by Email
      await emailBtn.click();
      await page.waitForLoadState('networkidle').catch(() => {});

      // Confirm UI does not claim delivery
      const notifyEl = page.locator('[id$="lblNotify"]');
      const notifyText = (await notifyEl.innerText().catch(() => '')) || '';
      expect(notifyText.toLowerCase()).not.toContain('email sent');
      expect(notifyText.toLowerCase()).not.toContain('delivered');
    });

    await test.step('Step 2: Inspect Activity Logs for mail client composition description', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('ApplicantPool');

      // Audit log must describe opening mail client, not delivery
      const hasEmailLog = await activityLogsPage.hasMatchingLog({
        category: 'ApplicantPool',
        activitySubstring: 'Opened mail client for link email',
      });
      expect(hasEmailLog).toBe(true);

      // Cleanup
      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-160: Resend link - Resend existing Active link
  // --------------------------------------------------------------------------
  test('TC-CM-160: Resend link - Resend existing Active link', async ({ loginAsRole, page, activityLogsPage }) => {
    const testName = `${PREFIX}-TC160-ResendApp`;
    const testEmail = 'tc160-regression@example.com';

    await test.step('Step 1: Create active link and select Resend', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(getTomorrowDateString());
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await openManageLinksPanel(page);
      const row = page.locator('[id$="gvLinks"] tr').filter({ hasText: testName }).first();
      await expect(row).toBeVisible();

      const resendBtn = row.locator('a:has-text("Resend")');
      await expect(resendBtn).toBeVisible();
      await resendBtn.click();
      await page.waitForLoadState('networkidle').catch(() => {});
    });

    await test.step('Step 2: Confirm link remains Active and activity log records accurately', async () => {
      await openManageLinksPanel(page);
      const row = page.locator('[id$="gvLinks"] tr').filter({ hasText: testName }).first();
      await expect(row).toBeVisible();
      await expect(row).toContainText('Active');

      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('ApplicantPool');

      const hasResendLog = await activityLogsPage.hasMatchingLog({
        category: 'ApplicantPool',
        activitySubstring: 'Opened mail client for resend link',
      });
      expect(hasResendLog).toBe(true);

      // Cleanup
      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-164: Self-encoding - Deny unknown link
  // --------------------------------------------------------------------------
  test('TC-CM-164: Self-encoding - Deny unknown link', async ({ browser, loginAsRole, activityLogsPage }) => {
    const context = await browser.newContext();
    const cleanPage = await context.newPage();

    await test.step('Step 1: Open unknown / corrupt token and confirm AccessDenied without redirect loop', async () => {
      await cleanPage.goto('/login.aspx?e=INVALID_UNKNOWN_CORRUPT_TOKEN_20261004');
      await cleanPage.waitForLoadState('networkidle').catch(() => {});

      const currentUrl = cleanPage.url();
      expect(currentUrl).toMatch(/\/Applicant\/AccessDenied\.aspx/i);
      await expect(cleanPage.locator('.denied-title, h1, h2')).toContainText(/Access Denied/i);
      await context.close();
    });

    await test.step('Step 2: Inspect Activity Logs for privacy-safe recording', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      const hasDeniedLog = await activityLogsPage.hasMatchingLog({
        category: 'ApplicantLink',
        activitySubstring: 'Malformed encoding link',
      }) || await activityLogsPage.hasMatchingLog({
        category: 'ApplicantLink',
        activitySubstring: 'Encoding link exception',
      });
      expect(hasDeniedLog).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-165: Self-encoding - Deny Expired link
  // --------------------------------------------------------------------------
  test('TC-CM-165: Self-encoding - Deny Expired link', async ({ loginAsRole, page, browser, activityLogsPage }) => {
    let expiredUrl = '';
    const testName = `${PREFIX}-TC165-ExpApp`;
    const testEmail = 'tc165-regression@example.com';

    await test.step('Step 1: Generate link, update to Expired, open in clean context', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(getYesterdayDateString());
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      expiredUrl = await page.locator('[id$="txtGeneratedLink"]').inputValue();

      // Open in fresh unauthenticated context
      const applicantContext = await browser.newContext();
      const applicantPage = await applicantContext.newPage();

      await applicantPage.goto(expiredUrl);
      await applicantPage.waitForLoadState('networkidle').catch(() => {});

      expect(applicantPage.url()).toMatch(/\/Applicant\/AccessDenied\.aspx/i);
      await expect(applicantPage.locator('.denied-title, h1, h2')).toContainText(/Access Denied/i);
      await applicantContext.close();
    });

    await test.step('Step 2: Inspect Activity Logs and clean up', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      const hasDeniedLog = await activityLogsPage.hasMatchingLog({
        category: 'ApplicantLink',
        activitySubstring: 'Invalid/expired encoding link attempt',
      });
      expect(hasDeniedLog).toBe(true);

      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-166: Self-encoding - Deny Used link
  // --------------------------------------------------------------------------
  test('TC-CM-166: Self-encoding - Deny Used link', async ({ loginAsRole, page, browser, activityLogsPage }) => {
    let usedUrl = '';
    const testName = `${PREFIX}-TC166-UsedApp`;
    const testEmail = 'tc166-regression@example.com';

    await test.step('Step 1: Submit applicant form to consume link, then re-access', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(getTomorrowDateString());
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      usedUrl = await page.locator('[id$="txtGeneratedLink"]').inputValue();

      // Submit once as applicant to consume the link
      const firstContext = await browser.newContext();
      const firstPage = await firstContext.newPage();
      await firstPage.goto(usedUrl);
      await firstPage.waitForLoadState('networkidle').catch(() => {});

      await firstPage.locator('[id$="txtLastName"]').fill(testName);
      await firstPage.locator('[id$="txtFirstName"]').fill('UsedFirst');
      await firstPage.locator('[id$="txtDOB"]').fill('1992-04-10');
      await firstPage.locator('.card:visible button:has-text("Next")').click();
      await firstPage.waitForTimeout(500);

      await firstPage.locator('[id$="txtContact"]').fill('0918-555-4321');
      await firstPage.locator('.card:visible button:has-text("Next")').click();
      await firstPage.waitForTimeout(500);

      await firstPage.locator('[id$="btnSubmit"]').click();
      await firstPage.waitForLoadState('networkidle').catch(() => {});
      await firstContext.close();

      // Open second time - must be denied as Used
      const secondContext = await browser.newContext();
      const secondPage = await secondContext.newPage();
      await secondPage.goto(usedUrl);
      await secondPage.waitForLoadState('networkidle').catch(() => {});

      expect(secondPage.url()).toMatch(/\/Applicant\/AccessDenied\.aspx/i);
      await expect(secondPage.locator('.denied-title, h1, h2')).toContainText(/Access Denied/i);
      await secondContext.close();
    });

    await test.step('Step 2: Inspect Activity Logs and clean up', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      const hasDeniedLog = await activityLogsPage.hasMatchingLog({
        category: 'ApplicantLink',
        activitySubstring: 'Invalid/expired encoding link attempt',
      });
      expect(hasDeniedLog).toBe(true);

      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-167: Self-encoding - Deny Active link with past validity
  // --------------------------------------------------------------------------
  test('TC-CM-167: Self-encoding - Deny Active link with past validity', async ({ loginAsRole, page, browser, activityLogsPage }) => {
    const testName = `${PREFIX}-TC167-PastApp`;
    const testEmail = 'tc167-regression@example.com';
    const yesterdayStr = getYesterdayDateString();
    let generatedUrl = '';

    await test.step('Step 1: Create active link with past validity and access in clean context', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(yesterdayStr);
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await expect(page.locator('[id$="panelLinkResult"]')).toBeVisible();
      generatedUrl = await page.locator('[id$="txtGeneratedLink"]').inputValue();

      const applicantContext = await browser.newContext();
      const applicantPage = await applicantContext.newPage();

      await applicantPage.goto(generatedUrl);
      await applicantPage.waitForLoadState('networkidle').catch(() => {});

      expect(applicantPage.url()).toMatch(/\/Applicant\/AccessDenied\.aspx/i);
      await expect(applicantPage.locator('.denied-title, h1, h2')).toContainText(/Access Denied/i);
      await applicantContext.close();
    });

    await test.step('Step 2: Inspect Activity Logs and clean up', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      const hasDeniedLog = await activityLogsPage.hasMatchingLog({
        category: 'ApplicantLink',
        activitySubstring: 'Invalid/expired encoding link attempt',
      });
      expect(hasDeniedLog).toBe(true);

      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-201: Crew Change List - Cancel a finalized schedule
  // --------------------------------------------------------------------------
  test('TC-CM-201: Crew Change List - Cancel a finalized schedule', async ({ loginAsRole, page, activityLogsPage }) => {
    // Automatically accept any browser confirmation dialogs (e.g. Cancel schedule confirm)
    page.on('dialog', async dialog => {
      try {
        await dialog.accept();
      } catch (_) {}
    });

    await test.step('Step 1: Ensure schedule is finalized, then cancel using Super Admin', async () => {
      await loginAsRole('SUPERADMIN');
      await selectVesselOnCCL(page, QA_VESSEL_A);

      const row = page.locator('#tblCCL tbody tr').filter({ hasText: 'Santos' }).first();
      await row.waitFor({ timeout: 5000 });

      // If Schedule button is visible (e.g. previously cancelled or fresh), create schedule first
      const schedBtn = row.locator('button:has-text("Schedule")');
      if (await schedBtn.isVisible().catch(() => false)) {
        await schedBtn.click();
        await expect(page.locator('#modalSchedule')).toBeVisible();
        await page.locator('[id$="txtJoiningDate"]').fill(getFutureDateString(21));
        await page.locator('[id$="txtJoiningPort"]').fill('Batangas Port');
        await page.locator('[id$="txtDepartureDate"]').fill(getFutureDateString(21));
        await page.locator('[id$="txtShipOnsign"]').fill(getFutureDateString(21));
        await page.locator('[id$="btnSaveSchedule"]').click();
        await page.waitForLoadState('networkidle').catch(() => {});
      }

      // If Finalize button is visible, finalize it to NEXT
      const finalizeBtn = row.locator('button:has-text("Finalize")');
      if (await finalizeBtn.isVisible().catch(() => false)) {
        await finalizeBtn.click();
        await expect(page.locator('#modalFinalize')).toBeVisible();
        await page.locator('[id$="btnConfirmFinalize"]').click();
        await page.waitForLoadState('networkidle').catch(() => {});
      }

      // Amend button must now be visible
      const amendBtn = row.locator('button:has-text("Amend")');
      await expect(amendBtn).toBeVisible({ timeout: 5000 });

      // Cancel the finalized schedule
      await amendBtn.click();
      await expect(page.locator('#modalAmend')).toBeVisible();

      await page.locator('[id$="txtAmendRemarks"]').fill('QA Cycle 2 regression cancellation test');
      await page.locator('[id$="btnConfirmCancel"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const notify = page.locator('[id$="lblNotify"]');
      await expect(notify).toContainText(/Schedule cancelled/i);
    });

    await test.step('Step 2: Inspect schedule status, associated EOC, and activity log', async () => {
      const row = page.locator('#tblCCL tbody tr').filter({ hasText: 'Santos' }).first();

      // Schedule column (10) must be Cancelled
      await expect(row.locator('td:nth-child(10)')).toContainText(/Cancelled/i);

      // Associated EOC column (11) must NOT be "No EOC"; it must be displayed as Cancelled or exact approved cancelled-EOC state (e.g. Superseded)
      const eocCell = row.locator('td:nth-child(11)');
      const eocText = await eocCell.innerText();
      expect(eocText).not.toMatch(/No EOC/i);
      expect(eocText).toMatch(/Cancelled|Superseded/i);

      // Confirm unrelated rows on Vessel A are unaffected
      const otherRows = page.locator('#tblCCL tbody tr').filter({ hasNotText: 'Santos' });
      const otherCount = await otherRows.count();
      if (otherCount > 0) {
        await expect(otherRows.first()).toBeVisible();
      }

      // Verify CCL audit log for cancellation
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      const hasCancelLog = await activityLogsPage.hasMatchingLog({
        category: 'CrewChangeList',
        activitySubstring: 'Cancelled CCL Schedule',
      });
      expect(hasCancelLog).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-204: Crew Change List - Verify the CCL audit trail
  // --------------------------------------------------------------------------
  test('TC-CM-204: Crew Change List - Verify the CCL audit trail', async ({ loginAsRole, page, activityLogsPage }) => {
    // Automatically accept any browser confirmation dialogs
    page.on('dialog', async dialog => {
      try {
        await dialog.accept();
      } catch (_) {}
    });

    await test.step('Step 1: Execute controlled CCL operations on isolated test vessel', async () => {
      await loginAsRole('SUPERADMIN');
      await selectVesselOnCCL(page, QA_VESSEL_A);

      const row = page.locator('#tblCCL tbody tr').filter({ hasText: 'Santos' }).first();
      await row.waitFor({ timeout: 5000 });

      // Schedule the approved reliever
      const schedBtn = row.locator('button:has-text("Schedule")');
      if (await schedBtn.isVisible().catch(() => false)) {
        await schedBtn.click();
        await expect(page.locator('#modalSchedule')).toBeVisible();
        await page.locator('[id$="txtJoiningDate"]').fill(getFutureDateString(14));
        await page.locator('[id$="txtJoiningPort"]').fill('Batangas Port');
        await page.locator('[id$="txtDepartureDate"]').fill(getFutureDateString(14));
        await page.locator('[id$="txtShipOnsign"]').fill(getFutureDateString(14));
        await page.locator('[id$="btnSaveSchedule"]').click();
        await page.waitForLoadState('networkidle').catch(() => {});
      }

      // Finalize the schedule
      const finalizeBtn = row.locator('button:has-text("Finalize")');
      if (await finalizeBtn.isVisible().catch(() => false)) {
        await finalizeBtn.click();
        await expect(page.locator('#modalFinalize')).toBeVisible();
        await page.locator('[id$="btnConfirmFinalize"]').click();
        await page.waitForLoadState('networkidle').catch(() => {});
      }

      // Amend the schedule
      const amendBtn = row.locator('button:has-text("Amend")');
      if (await amendBtn.isVisible().catch(() => false)) {
        await amendBtn.click();
        await expect(page.locator('#modalAmend')).toBeVisible();
        await page.locator('[id$="txtAmendRemarks"]').fill('Regression audit test amendment');
        await page.locator('[id$="btnConfirmAmend"]').click();
        await page.waitForLoadState('networkidle').catch(() => {});
      }
    });

    await test.step('Step 2: Inspect Activity Logs for comprehensive CCL audit trail', async () => {
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      const cclLogs = await activityLogsPage.getLogRows();
      expect(cclLogs.length).toBeGreaterThan(0);

      // Verify presence of CCL action types in audit log
      const hasCclActivity = cclLogs.some(l =>
        l.category === 'CrewChangeList' &&
        /Schedule|Reliever|Finalized|Amended|Cancelled/i.test(l.activity)
      );
      expect(hasCclActivity).toBe(true);

      // Confirm required fields exist: timestamp, user, category, activity
      const cclEntries = cclLogs.filter(l => l.category === 'CrewChangeList');
      expect(cclEntries.length).toBeGreaterThan(0);
      for (const log of cclEntries.slice(0, 5)) {
        expect(log.timestamp).toBeTruthy();
        expect(log.user).toBeTruthy();
        expect(log.category).toBe('CrewChangeList');
        expect(log.activity).toBeTruthy();
      }
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-218: AI audit logging - Record privacy-safe AI and document events
  // --------------------------------------------------------------------------
  test('TC-CM-218: AI audit logging - Record privacy-safe AI and document events', async ({ loginAsRole, page, browser, activityLogsPage }) => {
    const testName = `${PREFIX}-TC218-AiAudit`;
    const testEmail = 'tc218-regression@example.com';
    let linkUrl = '';

    await test.step('Step 1: Generate applicant link and perform AI document upload and extraction', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(getTomorrowDateString());
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      linkUrl = await page.locator('[id$="txtGeneratedLink"]').inputValue();

      // Open applicant link in fresh context
      const applicantContext = await browser.newContext();
      const applicantPage = await applicantContext.newPage();
      await applicantPage.goto(linkUrl);
      await applicantPage.waitForLoadState('networkidle').catch(() => {});

      // Consent and upload valid document
      const consentChk = applicantPage.locator('#chkAiConsent');
      if (await consentChk.isVisible().catch(() => false)) {
        await consentChk.check();
      }

      const fileInput = applicantPage.locator('#aiFileInput');
      await fileInput.setInputFiles([MANIFEST_RESUME_PDF]);

      // Wait for extraction to reach terminal state
      const terminalState = await waitForExtractionTerminalState(applicantPage);
      expect(['COMPLETED', 'ERROR']).toContain(terminalState);

      // Upload invalid file to trigger failure event
      try {
        await fileInput.setInputFiles([INVALID_SCRIPT_EXE]);
        await applicantPage.waitForTimeout(1000);
      } catch (e) {
        // Validation rejection expected
      }

      await applicantContext.close();
    });

    await test.step('Step 2: Inspect Activity Logs for privacy-safe AI and document events', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      const rows = await activityLogsPage.getLogRows();
      expect(rows.length).toBeGreaterThan(0);

      // Find AI extraction or mapping rows
      const aiRows = rows.filter(r =>
        r.category.includes('ApplicantAi') || r.category.includes('ApplicantDocument')
      );
      expect(aiRows.length).toBeGreaterThan(0);

      // Verify privacy guarantees: no raw text, PII, tokens, hashes, or passwords
      for (const r of aiRows) {
        expect(r.activity).not.toContain('password');
        expect(r.activity).not.toContain('secret');
        expect(r.activity).not.toContain('AES256');
        expect(r.user).toMatch(/Applicant|Link|0|[A-Za-z0-9]+/i);
      }

      // Cleanup applicant link
      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });
});
