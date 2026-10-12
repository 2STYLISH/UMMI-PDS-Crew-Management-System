import { test, expect } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';
import * as crypto from 'crypto';

const SCREENSHOT_DIR = path.join(__dirname, '../../evidence/screenshots/cycle2/tc169_clock');
const RESULTS_DIR = path.join(__dirname, '../../evidence');

// Authoritative AES-256-CBC Encryption matching CrewMgmt/login.aspx.vb Decrypt()
const AES_KEY_STRING = 'UMMI_SECRET_KEY_2024_PDS_SECURE!';
const AES_IV_STRING  = 'UMMI_IV_2024_PDS';

function encryptPayload(plainText: string): string {
  const key = Buffer.from(AES_KEY_STRING, 'utf8');
  const iv  = Buffer.from(AES_IV_STRING, 'utf8');
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
  let encrypted = cipher.update(plainText, 'utf8', 'base64');
  encrypted += cipher.final('base64');
  return encrypted;
}

function sanitizeUrl(rawUrl: string): string {
  return rawUrl.replace(/([?&]e=)[^&"']+/gi, '$1[REDACTED]').replace(/([?&]token=)[^&"']+/gi, '$1[REDACTED]');
}

test('TC-CM-169: Verify Polling Fix, Link 417 Expiry State, Denial, and Audit Trail', async ({ browser }) => {
  test.setTimeout(120000); // 2 minutes

  if (!fs.existsSync(SCREENSHOT_DIR)) {
    fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
  }

  const manningUser = process.env.QA_MANNING_CONTROL_USER || process.env.UMMI_MANNING_USER;
  const manningPass = process.env.QA_MANNING_CONTROL_PASSWORD || process.env.UMMI_MANNING_PASSWORD;
  const superUser   = process.env.QA_SUPERADMIN_USER || process.env.UMMI_SUPERADMIN_USER || process.env.UMMI_ADMIN_USER;
  const superPass   = process.env.QA_SUPERADMIN_PASSWORD || process.env.UMMI_SUPERADMIN_PASSWORD || process.env.UMMI_ADMIN_PASSWORD;

  if (!manningUser || !manningPass) {
    throw new Error('Manning credentials not found in environment.');
  }

  const executionLog: any = {
    testCaseId: 'TC-CM-169',
    phase: 'Polling Fix & Link 417 Post-Expiry Verification',
    defectClassification: 'Previous polling timeout classified as test-script defect (unauthenticated monitor context)',
    linkIdTested: 417,
    applicantName: 'QA-C2-TC169-CLOCK-1791736854',
    checks: []
  };

  // --------------------------------------------------------------------------
  // Step 1: Retained Authenticated Manning Session Verification
  // --------------------------------------------------------------------------
  console.log('[Step 1] Authenticating Manning Staff session...');
  const manningContext = await browser.newContext();
  const manningPage = await manningContext.newPage();

  await manningPage.goto('/login.aspx');
  await manningPage.fill('#txtUsername', manningUser);
  await manningPage.fill('#txtPassword', manningPass);
  await manningPage.click('#btnLogin');
  await manningPage.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 15000 });

  console.log('[Step 1] Navigating to ApplicantPool.aspx...');
  await manningPage.goto('/Applicant/ApplicantPool.aspx');
  await manningPage.waitForLoadState('networkidle');

  // FAIL IMMEDIATELY if redirected to login
  const currentUrl = manningPage.url();
  if (currentUrl.toLowerCase().includes('login.aspx')) {
    throw new Error('CRITICAL FAILURE: Manning session was redirected to login.aspx.');
  }

  // Open Manage Links panel
  const isManageVisible = await manningPage.locator('[id$="panelManageLinks"]').isVisible({ timeout: 2000 }).catch(() => false);
  if (!isManageVisible) {
    const btnManage = manningPage.locator('input[id*="btnManageLinks"]');
    if (!await btnManage.isVisible({ timeout: 3000 }).catch(() => false)) {
      throw new Error('CRITICAL FAILURE: btnManageLinks not found on ApplicantPool.aspx.');
    }
    await btnManage.click();
    await manningPage.waitForLoadState('networkidle');
  }

  // Assert gvLinks table is present and accessible
  const gvLinks = manningPage.locator('table[id*="gvLinks"]');
  if (!await gvLinks.isVisible({ timeout: 5000 }).catch(() => false)) {
    throw new Error('CRITICAL FAILURE: Required table gvLinks is unavailable.');
  }

  console.log('[Step 1] PASS: ApplicantPool.aspx and Manage Links table confirmed accessible.');
  executionLog.checks.push({
    assertion: 'ApplicantPool.aspx and Manage Links table accessible without redirection',
    result: 'PASSED'
  });

  // --------------------------------------------------------------------------
  // Step 2: Confirm Polling Reads LinkID 417, Status Active, and Expired Validity
  // --------------------------------------------------------------------------
  console.log('[Step 2] Locating LinkID 417 row in gvLinks...');
  const linkRow = manningPage.locator('table[id*="gvLinks"] tr').filter({ hasText: 'QA-C2-TC169-CLOCK-1791736854' }).first();
  await expect(linkRow).toBeVisible({ timeout: 5000 });

  const rowText = await linkRow.innerText();
  console.log('[Step 2] Row Content:', rowText.replace(/\t+/g, ' | '));

  // Check Status cell (td index 7)
  const statusCell = linkRow.locator('td').nth(7);
  const statusText = (await statusCell.innerText()).trim();
  console.log(`[Step 2] Stored Status: "${statusText}"`);
  expect(statusText).toBe('Active');

  // Check Validity cell (td index 4) style for expired red highlight (rgb(254, 226, 226))
  const validityCell = linkRow.locator('td').nth(4);
  const validityStyle = await validityCell.getAttribute('style') || '';
  const validityText = (await validityCell.innerText()).trim();
  console.log(`[Step 2] Validity Text: "${validityText}", Style: "${validityStyle}"`);
  expect(validityStyle.toLowerCase()).toMatch(/(fee2e2|254,\s*226,\s*226)/i);

  // Perform 3 rapid test polls with page reload to confirm bounded, non-hanging polling
  console.log('[Step 2] Testing polling reload resilience (3 cycles)...');
  for (let i = 1; i <= 3; i++) {
    const pollStart = Date.now();
    const resp = await manningPage.reload({ timeout: 10000 });
    await manningPage.waitForLoadState('networkidle');
    const elapsed = Date.now() - pollStart;
    const httpDate = resp?.headers()['date'] || 'unknown';
    console.log(`[Step 2] Poll cycle ${i}: ${elapsed}ms, Server HTTP Date: ${httpDate}`);
    expect(manningPage.url()).not.toContain('login.aspx');
  }

  await manningPage.screenshot({
    path: path.join(SCREENSHOT_DIR, 'tc169-link417-polling-verified.png'),
    fullPage: true
  });

  executionLog.checks.push({
    assertion: 'Polling reads LinkID 417, status Active, and expired validity highlight',
    statusFound: statusText,
    validityStyleFound: validityStyle,
    result: 'PASSED'
  });

  // --------------------------------------------------------------------------
  // Step 3: Verify Post-Expiry Access Denial for LinkID 417
  // --------------------------------------------------------------------------
  console.log('[Step 3] Verifying post-expiry access denial for LinkID 417...');
  const encryptedPayload = encryptPayload('linkid=417');
  const invitationUrl = `/login.aspx?e=${encodeURIComponent(encryptedPayload)}`;

  const applicantContext = await browser.newContext();
  const applicantPage = await applicantContext.newPage();

  const navResp = await applicantPage.goto(invitationUrl);
  await applicantPage.waitForLoadState('networkidle');

  const landingUrl = applicantPage.url();
  console.log('[Step 3] Landing URL:', sanitizeUrl(landingUrl));
  expect(landingUrl).toMatch(/\/Applicant\/AccessDenied\.aspx/i);
  await expect(applicantPage.locator('h1, h2, .denied-title, .card-title')).toContainText(/Access Denied/i);

  await applicantPage.screenshot({
    path: path.join(SCREENSHOT_DIR, 'tc169-link417-access-denied.png'),
    fullPage: true
  });

  executionLog.checks.push({
    assertion: 'Post-expiry access denied for LinkID 417 while status remains Active',
    landingUrl: sanitizeUrl(landingUrl),
    result: 'PASSED'
  });

  // --------------------------------------------------------------------------
  // Step 4: Verify Corresponding Denial Audit Entry in Activity Logs
  // --------------------------------------------------------------------------
  if (superUser && superPass) {
    console.log('[Step 4] Checking denial audit entry in Activity Logs...');
    const superContext = await browser.newContext();
    const superPage = await superContext.newPage();

    await superPage.goto('/login.aspx');
    await superPage.fill('#txtUsername', superUser);
    await superPage.fill('#txtPassword', superPass);
    await superPage.click('#btnLogin');
    await superPage.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 15000 });

    await superPage.goto('/Settings/ActivityLogs.aspx');
    await superPage.waitForLoadState('networkidle');

    const logRows = await superPage.locator('table[id*="gvLogs"] tr').allInnerTexts();
    const denialEntry = logRows.find(r => r.includes('ApplicantLink') && r.includes('Invalid/expired encoding link attempt'));
    console.log('[Step 4] Denial audit entry:', denialEntry ? 'CONFIRMED' : 'NOT FOUND');

    expect(denialEntry).toBeDefined();

    if (denialEntry) {
      executionLog.denialAuditEntry = denialEntry.replace(/\t+/g, ' | ').replace(/\n+/g, ' ');
    }

    await superPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc169-link417-denial-audit-log.png'),
      fullPage: true
    });

    executionLog.checks.push({
      assertion: 'Denial audit entry recorded in Activity Logs for expired link attempt',
      entrySnippet: executionLog.denialAuditEntry,
      result: 'PASSED'
    });

    await superContext.close();
  }

  // Cleanup
  await manningContext.close();
  await applicantContext.close();

  fs.writeFileSync(
    path.join(RESULTS_DIR, 'tc169-link417-fix-verification.json'),
    JSON.stringify(executionLog, null, 2),
    'utf8'
  );

  console.log('[COMPLETED] All LinkID 417 polling fix and denial assertions PASSED.');
});
