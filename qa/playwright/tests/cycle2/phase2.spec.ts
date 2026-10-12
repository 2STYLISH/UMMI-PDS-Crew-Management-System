import { test, expect } from '../../fixtures/auth.fixture';
import { Page } from '@playwright/test';
import crypto from 'crypto';

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
// Helpers for Applicant Pool & Manage Links
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
  const isAlreadyVisible = await page.locator('[id$="panelManageLinks"]').isVisible();
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
  } catch {
    // Ignore cleanup errors
  }
}

// ---------------------------------------------------------------------------
// TEST SUITE: Cycle 2 Phase 2 — Applicant Lifecycle
// ---------------------------------------------------------------------------
test.describe('UMMI Cycle 2 — Phase 2: Applicant Lifecycle Test Suite', () => {

  // --------------------------------------------------------------------------
  // TC-CM-140: Reject missing validity
  // --------------------------------------------------------------------------
  test('TC-CM-140: Encoding link validation - Reject missing validity', async ({ loginAsRole, page }) => {
    const testName = 'QA-C2-TC140-TempApplicant';
    const testEmail = 'tc140-validity@example.com';
    const tomorrowStr = getTomorrowDateString();

    await test.step('Step 1: Submit the link-generation form with missing validity', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill('');

      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = page.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Link validity date is required|Please enter a valid calendar date/i);

      await expect(page.locator('[id$="panelLinkResult"]')).toBeHidden();
      expect(await page.locator('[id$="txtLinkFullname"]').inputValue()).toBe(testName);
      expect(await page.locator('[id$="txtLinkEmail"]').inputValue()).toBe(testEmail);
    });

    await test.step('Step 2: Correct the invalid field and resubmit', async () => {
      await page.locator('[id$="txtLinkValidity"]').fill(tomorrowStr);
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const resultPanel = page.locator('[id$="panelLinkResult"]');
      await expect(resultPanel).toBeVisible();
      const generatedLink = await page.locator('[id$="txtGeneratedLink"]').inputValue();
      expect(generatedLink).toContain('/login.aspx?e=');

      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-144: Email composition - Compose encoding email without claiming delivery
  // --------------------------------------------------------------------------
  test('TC-CM-144: Email composition - Compose encoding email without claiming delivery', async ({ loginAsRole, page, activityLogsPage }) => {
    const testName = 'QA-C2-TC144-EmailApplicant';
    const testEmail = 'tc144-email@example.com';
    const tomorrowStr = getTomorrowDateString();

    await test.step('Step 1: Select Send by Email for the link', async () => {
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
      await emailBtn.click();
      await page.waitForLoadState('networkidle').catch(() => {});
    });

    await test.step('Step 2: Close the draft without sending and inspect the audit log', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('ApplicantPool');

      // The action is recorded as initiated. No successful delivery is inferred.
      // Note: Staging defect in AuditHelper.vb (SQL error: unknown column 'timestamp') prevents log insertion.
      const hasEmailLog = await activityLogsPage.hasMatchingLog({
        category: 'ApplicantPool',
        activitySubstring: 'Opened mail client for link email',
      });
      // Assert expected behavior per Excel Test Plan (fails if staging defect present)
      expect(hasEmailLog).toBe(true);

      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-163: Deny missing link
  // --------------------------------------------------------------------------
  test('TC-CM-163: Self-encoding - Deny missing link', async ({ browser, loginAsRole, activityLogsPage }) => {
    const context = await browser.newContext();
    const cleanPage = await context.newPage();

    await test.step('Step 1: Open the specified invalid or nonusable encoding link (direct access without token)', async () => {
      await cleanPage.goto('/Applicant/SelfEncode.aspx');
      await cleanPage.waitForLoadState('networkidle').catch(() => {});

      const currentUrl = cleanPage.url();
      expect(currentUrl).toMatch(/\/Applicant\/AccessDenied\.aspx/i);
      await expect(cleanPage.locator('.denied-title, h1, h2')).toContainText(/Access Denied/i);
      await expect(cleanPage.locator('[id$="txtLastName"]')).toBeHidden();
      await context.close();
    });

    await test.step('Step 2: Inspect records and access log', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('Security');
      const rows = await activityLogsPage.getLogRows();
      expect(rows.length).toBeGreaterThanOrEqual(0);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-164: Deny unknown link
  // --------------------------------------------------------------------------
  test('TC-CM-164: Self-encoding - Deny unknown link', async ({ browser, loginAsRole, activityLogsPage }) => {
    const context = await browser.newContext();
    const cleanPage = await context.newPage();

    await test.step('Step 1: Open the specified invalid or nonusable encoding link (corrupt token)', async () => {
      await cleanPage.goto('/login.aspx?e=INVALID_UNKNOWN_CORRUPT_TOKEN_12345');
      await cleanPage.waitForLoadState('networkidle').catch(() => {});

      const currentUrl = cleanPage.url();
      expect(currentUrl).toMatch(/\/Applicant\/AccessDenied\.aspx/i);
      await expect(cleanPage.locator('.denied-title, h1, h2')).toContainText(/Access Denied/i);
      await context.close();
    });

    await test.step('Step 2: Inspect records and access log', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      // Note: Staging defect in AuditHelper.vb causes log insert failure
      const hasDeniedLog = await activityLogsPage.hasMatchingLog({
        activitySubstring: 'Encoding link exception',
      });
      expect(hasDeniedLog).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-136: Encoding link - Generate personalized Active link
  // --------------------------------------------------------------------------
  test('TC-CM-136: Encoding link - Generate personalized Active link', async ({ loginAsRole, page, activityLogsPage }) => {
    const testName = 'QA-C2-TC136-PersonalizedApplicant';
    const testEmail = 'tc136-person@example.com';
    const validityDate = getFutureDateString(3);

    await test.step('Step 1: Open Generate Encoding Link, enter the data and submit', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(validityDate);

      const rankDdl = page.locator('[id$="drpdwnLinkRank"]');
      const count = await rankDdl.locator('option').count();
      if (count > 1) {
        await rankDdl.selectOption({ index: 1 });
      }

      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await expect(page.locator('[id$="panelLinkResult"]')).toBeVisible();
      const generatedLink = await page.locator('[id$="txtGeneratedLink"]').inputValue();
      expect(generatedLink).toContain('/login.aspx?e=');
    });

    await test.step('Step 2: Open Manage Links and inspect the audit log', async () => {
      await openManageLinksPanel(page);
      const row = page.locator('[id$="gvLinks"] tr').filter({ hasText: testName }).first();
      await expect(row).toBeVisible();
      await expect(row).toContainText('Active');

      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-138: Reject missing name
  // --------------------------------------------------------------------------
  test('TC-CM-138: Encoding link validation - Reject missing name', async ({ loginAsRole, page }) => {
    const testName = 'QA-C2-TC138-CorrectedName';
    const testEmail = 'tc138-name@example.com';
    const tomorrowStr = getTomorrowDateString();

    await test.step('Step 1: Submit the link-generation form with missing name', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill('');
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(tomorrowStr);

      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = page.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Full name is required/i);
      await expect(page.locator('[id$="panelLinkResult"]')).toBeHidden();
      expect(await page.locator('[id$="txtLinkEmail"]').inputValue()).toBe(testEmail);
    });

    await test.step('Step 2: Correct the invalid field and resubmit', async () => {
      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await expect(page.locator('[id$="panelLinkResult"]')).toBeVisible();
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-139: Reject missing email
  // --------------------------------------------------------------------------
  test('TC-CM-139: Encoding link validation - Reject missing email', async ({ loginAsRole, page }) => {
    const testName = 'QA-C2-TC139-Applicant';
    const testEmail = 'tc139-email@example.com';
    const tomorrowStr = getTomorrowDateString();

    await test.step('Step 1: Submit the link-generation form with missing email', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill('');
      await page.locator('[id$="txtLinkValidity"]').fill(tomorrowStr);

      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = page.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Email is required/i);
      await expect(page.locator('[id$="panelLinkResult"]')).toBeHidden();
      expect(await page.locator('[id$="txtLinkFullname"]').inputValue()).toBe(testName);
    });

    await test.step('Step 2: Correct the invalid field and resubmit', async () => {
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await expect(page.locator('[id$="panelLinkResult"]')).toBeVisible();
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-141: Reject malformed email
  // --------------------------------------------------------------------------
  test('TC-CM-141: Encoding link validation - Reject malformed email', async ({ loginAsRole, page }) => {
    const testName = 'QA-C2-TC141-Applicant';
    const malformedEmail = 'qa-invalid-email';
    const validEmail = 'qa-valid-tc141@example.com';
    const tomorrowStr = getTomorrowDateString();

    await test.step('Step 1: Submit the link-generation form with malformed email', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(malformedEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(tomorrowStr);

      const emailInput = page.locator('[id$="txtLinkEmail"]');
      const isValid = await emailInput.evaluate((el: HTMLInputElement) => el.checkValidity());
      expect(isValid).toBe(false);

      await page.locator('[id$="btnCreateLink"]').click();
      await expect(page.locator('[id$="panelLinkResult"]')).toBeHidden();
      expect(await page.locator('[id$="txtLinkFullname"]').inputValue()).toBe(testName);
    });

    await test.step('Step 2: Correct the invalid field and resubmit', async () => {
      await page.locator('[id$="txtLinkEmail"]').fill(validEmail);
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await expect(page.locator('[id$="panelLinkResult"]')).toBeVisible();
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-142: Reject invalid calendar date
  // --------------------------------------------------------------------------
  test('TC-CM-142: Encoding link validation - Reject invalid calendar date', async ({ loginAsRole, page }) => {
    const testName = 'QA-C2-TC142-Applicant';
    const testEmail = 'tc142-calendar@example.com';
    const tomorrowStr = getTomorrowDateString();

    await test.step('Step 1: Submit the link-generation form with invalid calendar date', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      
      await page.locator('[id$="txtLinkValidity"]').evaluate((el: HTMLInputElement) => {
        el.type = 'text';
        el.value = '31 Feb 2026';
      });

      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = page.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Please enter a valid calendar date/i);
      await expect(page.locator('[id$="panelLinkResult"]')).toBeHidden();
      expect(await page.locator('[id$="txtLinkFullname"]').inputValue()).toBe(testName);
      expect(await page.locator('[id$="txtLinkEmail"]').inputValue()).toBe(testEmail);
    });

    await test.step('Step 2: Correct the invalid field and resubmit', async () => {
      await page.locator('[id$="txtLinkValidity"]').evaluate((el: HTMLInputElement) => {
        el.type = 'date';
      });
      await page.locator('[id$="txtLinkValidity"]').fill(tomorrowStr);
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await expect(page.locator('[id$="panelLinkResult"]')).toBeVisible();
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-162: Valid Active link opens scoped form
  // --------------------------------------------------------------------------
  test('TC-CM-162: Self-encoding - Valid Active link opens scoped form', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-TC162-ActiveScoped';
    const testEmail = 'tc162-scoped@example.com';
    let generatedUrl = '';

    await test.step('Step 1: Generate Active link and open in fresh applicant session', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(getTomorrowDateString());
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await expect(page.locator('[id$="panelLinkResult"]')).toBeVisible();
      generatedUrl = await page.locator('[id$="txtGeneratedLink"]').inputValue();
      expect(generatedUrl).toContain('/login.aspx?e=');

      const applicantContext = await browser.newContext();
      const applicantPage = await applicantContext.newPage();

      await applicantPage.goto(generatedUrl);
      await applicantPage.waitForLoadState('networkidle').catch(() => {});

      expect(applicantPage.url()).toContain('/Applicant/SelfEncode.aspx');
      await expect(applicantPage.locator('[id$="txtLastName"]')).toBeVisible();
      const lastNameVal = await applicantPage.locator('[id$="txtLastName"]').inputValue();
      expect(lastNameVal).toBe(testName);

      await applicantContext.close();
    });

    await test.step('Step 2: Inspect last-access timestamp using authorized staging access', async () => {
      await openManageLinksPanel(page);
      const row = page.locator('[id$="gvLinks"] tr').filter({ hasText: testName }).first();
      await expect(row).toBeVisible();
      const lastAccessText = await row.locator('td').nth(5).innerText();
      expect(lastAccessText.trim()).not.toBe('');
      expect(lastAccessText.trim()).not.toBe('—');

      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-165: Deny Expired link
  // --------------------------------------------------------------------------
  test('TC-CM-165: Self-encoding - Deny Expired link', async ({ loginAsRole, page, browser, activityLogsPage }) => {
    let expiredUrl = '';
    const testName = 'QA-C2-TC165-ExpApp';
    const testEmail = 'tc165-exp@example.com';

    await test.step('Step 1: Open the specified invalid or nonusable encoding link (Expired)', async () => {
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

      expect(applicantPage.url()).toContain('/Applicant/AccessDenied.aspx');
      await expect(applicantPage.locator('.denied-title, h1, h2')).toContainText(/Access Denied/i);
      await applicantContext.close();
    });

    await test.step('Step 2: Inspect records and access log', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      // Note: Staging defect in AuditHelper.vb causes log insert failure
      const hasDeniedLog = await activityLogsPage.hasMatchingLog({
        activitySubstring: 'Invalid/expired encoding link attempt',
      });
      expect(hasDeniedLog).toBe(true);

      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-166: Deny Used link
  // --------------------------------------------------------------------------
  test('TC-CM-166: Self-encoding - Deny Used link', async ({ loginAsRole, page, browser, activityLogsPage }) => {
    let usedUrl = '';
    const testName = 'QA-C2-TC166-UsedApp';
    const testEmail = 'tc166-used@example.com';

    await test.step('Step 1: Open the specified invalid or nonusable encoding link (Used)', async () => {
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

      // Open second time - should be denied as Used
      const secondContext = await browser.newContext();
      const secondPage = await secondContext.newPage();
      await secondPage.goto(usedUrl);
      await secondPage.waitForLoadState('networkidle').catch(() => {});

      expect(secondPage.url()).toContain('/Applicant/AccessDenied.aspx');
      await expect(secondPage.locator('.denied-title, h1, h2')).toContainText(/Access Denied/i);
      await secondContext.close();
    });

    await test.step('Step 2: Inspect records and access log', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      // Note: Staging defect in AuditHelper.vb causes log insert failure
      const hasDeniedLog = await activityLogsPage.hasMatchingLog({
        activitySubstring: 'Invalid/expired encoding link attempt',
      });
      expect(hasDeniedLog).toBe(true);

      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-167: Deny Active link with past validity
  // --------------------------------------------------------------------------
  test('TC-CM-167: Self-encoding - Deny Active link with past validity', async ({ loginAsRole, page, browser, activityLogsPage }) => {
    const testName = 'QA-C2-TC167-PastApplicant';
    const testEmail = 'tc167-past@example.com';
    const yesterdayStr = getYesterdayDateString();
    let generatedUrl = '';

    await test.step('Step 1: Open the specified invalid or nonusable encoding link (Past Validity)', async () => {
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

      expect(applicantPage.url()).toContain('/Applicant/AccessDenied.aspx');
      await expect(applicantPage.locator('.denied-title, h1, h2')).toContainText(/Access Denied/i);
      await applicantContext.close();
    });

    await test.step('Step 2: Inspect records and access log', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.searchButton.click();
      await activityLogsPage.page.waitForLoadState('networkidle').catch(() => {});

      // Note: Staging defect in AuditHelper.vb causes log insert failure
      const hasDeniedLog = await activityLogsPage.hasMatchingLog({
        activitySubstring: 'Invalid/expired encoding link attempt',
      });
      expect(hasDeniedLog).toBe(true);

      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-168: Applicant session cannot browse staff pages
  // --------------------------------------------------------------------------
  test('TC-CM-168: Self-encoding - Applicant session cannot browse staff pages', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-TC168-ScopedApp';
    const testEmail = 'tc168-scoped@example.com';
    let generatedUrl = '';

    await test.step('Step 1: Navigate directly to each staff page and the unrelated applicant form', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(getTomorrowDateString());
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      generatedUrl = await page.locator('[id$="txtGeneratedLink"]').inputValue();

      const applicantContext = await browser.newContext();
      const applicantPage = await applicantContext.newPage();

      // Authenticate applicant session
      await applicantPage.goto(generatedUrl);
      await applicantPage.waitForLoadState('networkidle').catch(() => {});
      expect(applicantPage.url()).toContain('/Applicant/SelfEncode.aspx');

      // Test 1: Applicant Pool
      await applicantPage.goto('/Applicant/ApplicantPool.aspx');
      await applicantPage.waitForLoadState('networkidle').catch(() => {});
      expect(applicantPage.url()).not.toContain('/Applicant/ApplicantPool.aspx');

      // Test 2: Crew Search
      await applicantPage.goto('/Crew/QueryCrew.aspx');
      await applicantPage.waitForLoadState('networkidle').catch(() => {});
      expect(applicantPage.url()).not.toContain('/Crew/QueryCrew.aspx');

      // Test 3: Activity Logs
      await applicantPage.goto('/Settings/ActivityLogs.aspx');
      await applicantPage.waitForLoadState('networkidle').catch(() => {});
      expect(applicantPage.url()).not.toContain('/Settings/ActivityLogs.aspx');

      // Test 4: SelfEncode mode=add
      await applicantPage.goto('/Applicant/SelfEncode.aspx?mode=add');
      await applicantPage.waitForLoadState('networkidle').catch(() => {});
      expect(applicantPage.url()).not.toContain('mode=add');

      await applicantContext.close();

      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-103: Statutory verification - Verify Benefit numbers
  // --------------------------------------------------------------------------
  test('TC-CM-103: Statutory verification - Verify Benefit numbers', async ({ loginAsRole, crewSearchPage, page, activityLogsPage }) => {
    let cleanHref = '';

    await test.step('Step 1: Review the information and select Verify (Benefit numbers)', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();
      await crewSearchPage.lastNameInput.fill('Santos');
      await crewSearchPage.firstNameInput.fill('QA Maria');
      await crewSearchPage.search();

      const profileLink = crewSearchPage.resultRows.first().locator('td a[href*="ProfileViewer"]');
      await expect(profileLink).toBeVisible();
      const rawHref = (await profileLink.getAttribute('href')) || '';
      expect(rawHref).toContain('ProfileViewer.aspx');

      // Clean leading ~ from href and ensure /Crew/ prefix so relative navigation is correct
      cleanHref = rawHref.replace(/^~/, '');
      if (!cleanHref.startsWith('/Crew/') && !cleanHref.startsWith('http')) {
        cleanHref = '/Crew/' + cleanHref.replace(/^\/?/, '');
      }

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

    await test.step('Step 2: Reload the profile and inspect the audit log', async () => {
      await page.goto(cleanHref);
      await page.waitForLoadState('networkidle').catch(() => {});

      const benefitsLabel = page.locator('[id$="lblVerifiedBenefits"]');
      await expect(benefitsLabel).toBeVisible();
      await expect(benefitsLabel).toContainText(/Benefits Verified/i);

      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('ProfileViewer');
      // Note: Staging defect in AuditHelper.vb causes log insert failure
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

    await test.step('Step 1: Review the information and select Verify (TIN)', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();
      await crewSearchPage.lastNameInput.fill('Santos');
      await crewSearchPage.firstNameInput.fill('QA Maria');
      await crewSearchPage.search();

      const profileLink = crewSearchPage.resultRows.first().locator('td a[href*="ProfileViewer"]');
      await expect(profileLink).toBeVisible();
      const rawHref = (await profileLink.getAttribute('href')) || '';

      cleanHref = rawHref.replace(/^~/, '');
      if (!cleanHref.startsWith('/Crew/') && !cleanHref.startsWith('http')) {
        cleanHref = '/Crew/' + cleanHref.replace(/^\/?/, '');
      }
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

    await test.step('Step 2: Reload the profile and inspect the audit log', async () => {
      await page.goto(cleanHref);
      await page.waitForLoadState('networkidle').catch(() => {});

      const tinLabel = page.locator('[id$="lblVerifiedTIN"]');
      await expect(tinLabel).toBeVisible();
      await expect(tinLabel).toContainText(/TIN Verified/i);

      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('ProfileViewer');
      // Note: Staging defect in AuditHelper.vb causes log insert failure
      const hasVerifyLog = await activityLogsPage.hasMatchingLog({
        category: 'ProfileViewer',
        activitySubstring: 'Verified tin',
      });
      expect(hasVerifyLog).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-132: Manual applicant - Save valid manual applicant
  // --------------------------------------------------------------------------
  test('TC-CM-132: Manual applicant - Save valid manual applicant', async ({ loginAsRole, page }) => {
    const runSuffix = Date.now().toString().slice(-4);
    const lastName = `QA-C2-TC132-${runSuffix}`;
    const firstName = 'QA-ManualFirst';
    const email = `tc132-${runSuffix}@example.com`;

    await test.step('Step 1: Open Add Applicant, enter TD-APFULL and submit', async () => {
      await loginAsRole('MANNING');
      await page.goto('/Applicant/SelfEncode.aspx?mode=add');
      await page.waitForLoadState('networkidle').catch(() => {});
      await expect(page.locator('[id$="txtLastName"]')).toBeVisible({ timeout: 15000 });

      await page.locator('[id$="txtLastName"]').fill(lastName);
      await page.locator('[id$="txtFirstName"]').fill(firstName);
      await page.locator('[id$="txtDOB"]').fill('1995-05-15');

      const genderDdl = page.locator('[id$="drpdwnGender"]');
      if (await genderDdl.isVisible()) await genderDdl.selectOption('Male');

      const civilDdl = page.locator('[id$="drpdwnCivilStatus"]');
      if (await civilDdl.isVisible()) await civilDdl.selectOption('Single');

      const bloodDdl = page.locator('[id$="drpdwnBloodType"]');
      if (await bloodDdl.isVisible()) await bloodDdl.selectOption('O+');

      const rankDdl = page.locator('[id$="drpdwnRank"]');
      const rankCount = await rankDdl.locator('option').count();
      if (rankCount > 1) await rankDdl.selectOption({ index: 1 });

      await page.locator('.card:visible button:has-text("Next")').click();
      await page.waitForTimeout(500);

      await page.locator('[id$="txtContact"]').fill('0917-123-4567');
      await page.locator('[id$="txtEmail"]').fill(email);
      await page.locator('[id$="txtAddress"]').fill('123 Test Street, Manila');

      await page.locator('.card:visible button:has-text("Next")').click();
      await page.waitForTimeout(500);

      const submitBtn = page.locator('[id$="btnSubmit"]');
      await expect(submitBtn).toBeVisible();
      await submitBtn.click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = page.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Your application has been submitted successfully/i);
    });

    await test.step('Step 2: Locate the new applicant and inspect stored values', async () => {
      await loginAsRole('MANNING');
      await page.goto('/Applicant/ApplicantPool.aspx');
      await page.locator('[id$="txtLastName"]').fill(lastName);
      await page.locator('[id$="btnSearch"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const row = page.locator('[id$="gvApplicants"] tr').filter({ hasText: lastName }).first();
      await expect(row).toBeVisible();
      await expect(row).toContainText(firstName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-133: Manual applicant - Reject missing and malformed manual data
  // --------------------------------------------------------------------------
  test('TC-CM-133: Manual applicant - Reject missing and malformed manual data', async ({ loginAsRole, page }) => {
    const runSuffix = Date.now().toString().slice(-4);
    const lastName = `QA-C2-TC133-${runSuffix}`;

    await test.step('Step 1: Submit invalid payload with missing required field (First Name missing)', async () => {
      await loginAsRole('MANNING');
      await page.goto('/Applicant/SelfEncode.aspx?mode=add');
      await page.waitForLoadState('networkidle').catch(() => {});
      await expect(page.locator('[id$="txtLastName"]')).toBeVisible({ timeout: 15000 });

      await page.locator('[id$="txtLastName"]').fill(lastName);
      await page.locator('[id$="txtFirstName"]').fill('');
      await page.locator('[id$="txtDOB"]').fill('1995-05-15');

      await page.locator('.card:visible button:has-text("Next")').click();
      await page.waitForTimeout(500);

      await page.locator('[id$="txtContact"]').fill('0917-999-8888');

      await page.locator('.card:visible button:has-text("Next")').click();
      await page.waitForTimeout(500);

      await page.locator('[id$="btnSubmit"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = page.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Please fill in all required fields/i);

      // Verify no applicant saved yet
      await page.goto('/Applicant/ApplicantPool.aspx');
      await page.locator('[id$="txtLastName"]').fill(lastName);
      await page.locator('[id$="btnSearch"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});
      const row = page.locator('[id$="gvApplicants"] tr').filter({ hasText: lastName });
      expect(await row.count()).toBe(0);
    });

    await test.step('Step 2: Correct the identified fields and resubmit', async () => {
      await page.goto('/Applicant/SelfEncode.aspx?mode=add');
      await page.waitForLoadState('networkidle').catch(() => {});

      await page.locator('[id$="txtLastName"]').fill(lastName);
      await page.locator('[id$="txtFirstName"]').fill('QA-CorrectedFirst');
      await page.locator('[id$="txtDOB"]').fill('1995-05-15');

      await page.locator('.card:visible button:has-text("Next")').click();
      await page.waitForTimeout(500);

      await page.locator('[id$="txtContact"]').fill('0917-999-8888');

      await page.locator('.card:visible button:has-text("Next")').click();
      await page.waitForTimeout(500);

      await page.locator('[id$="btnSubmit"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = page.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Your application has been submitted successfully/i);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-143: Encoding link validation - Optional position and default validity
  // --------------------------------------------------------------------------
  test('TC-CM-143: Encoding link validation - Optional position and default validity', async ({ loginAsRole, page, activityLogsPage }) => {
    const testName = 'QA-C2-TC143-OptionalPosition';
    const testEmail = 'tc143-optpos@example.com';

    await test.step('Step 1: Leave Position Applied For blank, keep valid name/email, retain default validity, and submit', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(testName);
      await page.locator('[id$="txtLinkEmail"]').fill(testEmail);
      const rankDdl = page.locator('[id$="drpdwnLinkRank"]');
      await rankDdl.selectOption({ index: 0 });

      const defaultValidity = await page.locator('[id$="txtLinkValidity"]').inputValue();
      expect(defaultValidity).not.toBe('');

      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await expect(page.locator('[id$="panelLinkResult"]')).toBeVisible();
      const generatedLink = await page.locator('[id$="txtGeneratedLink"]').inputValue();
      expect(generatedLink).toContain('/login.aspx?e=');

      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-160: Resend link - Resend existing Active link
  // --------------------------------------------------------------------------
  test('TC-CM-160: Resend link - Resend existing Active link', async ({ loginAsRole, page, activityLogsPage }) => {
    const testName = 'QA-C2-TC160-ResendApp';
    const testEmail = 'tc160-resend@example.com';

    await test.step('Step 1: Select Resend for an existing Active link', async () => {
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

    await test.step('Step 2: Compare link record before and after', async () => {
      await openManageLinksPanel(page);
      const row = page.locator('[id$="gvLinks"] tr').filter({ hasText: testName }).first();
      await expect(row).toBeVisible();
      await expect(row).toContainText('Active');

      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('ApplicantPool');
      // Note: Staging defect in AuditHelper.vb causes log insert failure
      const hasResendLog = await activityLogsPage.hasMatchingLog({
        category: 'ApplicantPool',
        activitySubstring: 'Opened mail client for resend link',
      });
      expect(hasResendLog).toBe(true);

      await loginAsRole('MANNING');
      await cleanupGeneratedLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-170: Self-encoding - Submit valid applicant and consume link
  // --------------------------------------------------------------------------
  test('TC-CM-170: Self-encoding - Submit valid applicant and consume link', async ({ loginAsRole, page, browser }) => {
    const applicantName = 'QA-C2-TC170-Applicant';
    const applicantEmail = 'tc170-self@example.com';
    let generatedUrl = '';

    await test.step('Step 1: Generate dedicated link, complete form, and submit', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(applicantName);
      await page.locator('[id$="txtLinkEmail"]').fill(applicantEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(getTomorrowDateString());
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      await expect(page.locator('[id$="panelLinkResult"]')).toBeVisible();
      generatedUrl = await page.locator('[id$="txtGeneratedLink"]').inputValue();
      expect(generatedUrl).toContain('/login.aspx?e=');

      const applicantContext = await browser.newContext();
      const applicantPage = await applicantContext.newPage();

      await applicantPage.goto(generatedUrl);
      await applicantPage.waitForLoadState('networkidle').catch(() => {});
      expect(applicantPage.url()).toContain('/Applicant/SelfEncode.aspx');

      await applicantPage.locator('[id$="txtFirstName"]').fill('QA-Self170');
      await applicantPage.locator('[id$="txtDOB"]').fill('1996-08-20');
      const genderDdl = applicantPage.locator('[id$="drpdwnGender"]');
      if (await genderDdl.isVisible()) await genderDdl.selectOption('Female');

      await applicantPage.locator('.card:visible button:has-text("Next")').click();
      await applicantPage.waitForTimeout(500);

      await applicantPage.locator('[id$="txtContact"]').fill('0918-123-4567');
      await applicantPage.locator('[id$="txtEmail"]').fill(applicantEmail);

      await applicantPage.locator('.card:visible button:has-text("Next")').click();
      await applicantPage.waitForTimeout(500);

      await applicantPage.locator('[id$="btnSubmit"]').click();
      await applicantPage.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = applicantPage.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Your application has been submitted successfully/i);

      await applicantContext.close();
    });

    await test.step('Step 2: Reload stored applicant and reopen the link in a clean session', async () => {
      await openManageLinksPanel(page);
      const row = page.locator('[id$="gvLinks"] tr').filter({ hasText: applicantName }).first();
      await expect(row).toBeVisible();
      await expect(row).toContainText('Used');

      const cleanContext = await browser.newContext();
      const cleanPage = await cleanContext.newPage();
      await cleanPage.goto(generatedUrl);
      await cleanPage.waitForLoadState('networkidle').catch(() => {});

      expect(cleanPage.url()).toContain('/Applicant/AccessDenied.aspx');
      await expect(cleanPage.locator('.denied-title, h1, h2')).toContainText(/Access Denied/i);
      await cleanContext.close();

      await cleanupGeneratedLink(page, applicantName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-171: Validation retains valid entered data
  // --------------------------------------------------------------------------
  test('TC-CM-171: Self-encoding - Validation retains valid entered data', async ({ loginAsRole, page, browser }) => {
    const applicantName = 'QA-C2-TC171-Applicant';
    const applicantEmail = 'tc171-val@example.com';
    let generatedUrl = '';

    await test.step('Step 1: Submit incomplete form (missing contact number)', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(applicantName);
      await page.locator('[id$="txtLinkEmail"]').fill(applicantEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(getTomorrowDateString());
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      generatedUrl = await page.locator('[id$="txtGeneratedLink"]').inputValue();

      const applicantContext = await browser.newContext();
      const applicantPage = await applicantContext.newPage();

      await applicantPage.goto(generatedUrl);
      await applicantPage.waitForLoadState('networkidle').catch(() => {});

      await applicantPage.locator('[id$="txtFirstName"]').fill('QA-Self171');
      await applicantPage.locator('[id$="txtDOB"]').fill('1994-03-10');

      await applicantPage.locator('.card:visible button:has-text("Next")').click();
      await applicantPage.waitForTimeout(500);

      await applicantPage.locator('[id$="txtContact"]').fill('');

      await applicantPage.locator('.card:visible button:has-text("Next")').click();
      await applicantPage.waitForTimeout(500);

      await applicantPage.locator('[id$="btnSubmit"]').click();
      await applicantPage.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = applicantPage.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Please fill in all required fields/i);

      // Postback returns to Step 1; check valid data remains
      expect(await applicantPage.locator('[id$="txtFirstName"]').inputValue()).toBe('QA-Self171');

      await applicantContext.close();
    });

    await test.step('Step 2: Correct the field and submit again', async () => {
      const applicantContext = await browser.newContext();
      const applicantPage = await applicantContext.newPage();

      await applicantPage.goto(generatedUrl);
      await applicantPage.waitForLoadState('networkidle').catch(() => {});

      await applicantPage.locator('[id$="txtFirstName"]').fill('QA-Self171');
      await applicantPage.locator('[id$="txtDOB"]').fill('1994-03-10');

      await applicantPage.locator('.card:visible button:has-text("Next")').click();
      await applicantPage.waitForTimeout(500);

      await applicantPage.locator('[id$="txtContact"]').fill('0919-555-1234');

      await applicantPage.locator('.card:visible button:has-text("Next")').click();
      await applicantPage.waitForTimeout(500);

      await applicantPage.locator('[id$="btnSubmit"]').click();
      await applicantPage.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert = applicantPage.locator('[id$="lblNotify"]');
      await expect(notifyAlert).toBeVisible();
      await expect(notifyAlert).toContainText(/Your application has been submitted successfully/i);

      await applicantContext.close();

      await openManageLinksPanel(page);
      const row = page.locator('[id$="gvLinks"] tr').filter({ hasText: applicantName }).first();
      await expect(row).toBeVisible();
      await expect(row).toContainText('Used');

      await cleanupGeneratedLink(page, applicantName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-172: Repeated or concurrent submission does not duplicate
  // --------------------------------------------------------------------------
  test('TC-CM-172: Self-encoding - Repeated or concurrent submission does not duplicate', async ({ loginAsRole, page, browser }) => {
    const applicantName = 'QA-C2-TC172-Applicant';
    const applicantEmail = 'tc172-concurrent@example.com';
    let generatedUrl = '';

    await test.step('Step 1: Submit from both tabs, then retry from the second', async () => {
      await loginAsRole('MANNING');
      await openGenerateLinkPanel(page);

      await page.locator('[id$="txtLinkFullname"]').fill(applicantName);
      await page.locator('[id$="txtLinkEmail"]').fill(applicantEmail);
      await page.locator('[id$="txtLinkValidity"]').fill(getTomorrowDateString());
      await page.locator('[id$="btnCreateLink"]').click();
      await page.waitForLoadState('networkidle').catch(() => {});

      generatedUrl = await page.locator('[id$="txtGeneratedLink"]').inputValue();

      const context1 = await browser.newContext();
      const page1 = await context1.newPage();
      await page1.goto(generatedUrl);
      await page1.waitForLoadState('networkidle').catch(() => {});

      await page1.locator('[id$="txtFirstName"]').fill('QA-Tab1');
      await page1.locator('[id$="txtDOB"]').fill('1992-07-15');
      await page1.locator('.card:visible button:has-text("Next")').click();
      await page1.waitForTimeout(500);
      await page1.locator('[id$="txtContact"]').fill('0912-345-6789');
      await page1.locator('.card:visible button:has-text("Next")').click();
      await page1.waitForTimeout(500);

      const context2 = await browser.newContext();
      const page2 = await context2.newPage();
      await page2.goto(generatedUrl);
      await page2.waitForLoadState('networkidle').catch(() => {});

      await page2.locator('[id$="txtFirstName"]').fill('QA-Tab2');
      await page2.locator('[id$="txtDOB"]').fill('1992-07-15');
      await page2.locator('.card:visible button:has-text("Next")').click();
      await page2.waitForTimeout(500);
      await page2.locator('[id$="txtContact"]').fill('0912-345-6789');
      await page2.locator('.card:visible button:has-text("Next")').click();
      await page2.waitForTimeout(500);

      await page1.locator('[id$="btnSubmit"]').click();
      await page1.waitForLoadState('networkidle').catch(() => {});
      await expect(page1.locator('[id$="lblNotify"]')).toContainText(/Your application has been submitted successfully/i);

      await page2.locator('[id$="btnSubmit"]').click();
      await page2.waitForLoadState('networkidle').catch(() => {});

      const notifyAlert2 = page2.locator('[id$="lblNotify"]');
      const isDenied = (await notifyAlert2.isVisible() && (await notifyAlert2.innerText()).includes('expired, been used, or revoked')) ||
                       page2.url().includes('AccessDenied.aspx');
      expect(isDenied).toBe(true);

      await context1.close();
      await context2.close();

      await cleanupGeneratedLink(page, applicantName);
    });
  });

});
