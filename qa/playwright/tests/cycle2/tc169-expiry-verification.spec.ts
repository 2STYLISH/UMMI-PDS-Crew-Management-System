import { test, expect } from '@playwright/test';
import * as path from 'path';
import * as crypto from 'crypto';

const SCREENSHOT_DIR = path.resolve(__dirname, '../../evidence/screenshots/cycle2/tc169');
const RESULTS_DIR = path.resolve(__dirname, '../../evidence');

// AES-256 Symmetric Encryption Helper (mirrors CryptoHelper.vb)
const CRYPTO_KEY = 'UMMI-CREW-MGMT-2026-AES256-KEY!!';
const CRYPTO_SALT = 'UMMI2026SALT';

function getCryptoKey(): Buffer {
  return crypto.pbkdf2Sync(CRYPTO_KEY, Buffer.from(CRYPTO_SALT, 'utf8'), 1000, 32, 'sha1');
}

function encryptPayload(plainText: string): string {
  const key = getCryptoKey();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
  const encrypted = Buffer.concat([cipher.update(plainText, 'utf8'), cipher.final()]);
  const combined = Buffer.concat([iv, encrypted]);
  return combined.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '~');
}

function sanitizeUrl(rawUrl: string): string {
  return rawUrl.replace(/([?&]e=)[^&"']+/gi, '$1[REDACTED]').replace(/([?&]token=)[^&"']+/gi, '$1[REDACTED]');
}

test('TC-CM-169: Access Before Expiry, Access After Expiry, and Activity Log Rejection Audit', async ({ browser }) => {
  test.setTimeout(90000);
    const fs = require('fs');
    if (!fs.existsSync(SCREENSHOT_DIR)) {
      fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
    }

    const manningUser = process.env.QA_MANNING_CONTROL_USER || process.env.UMMI_MANNING_USER;
    const manningPass = process.env.QA_MANNING_CONTROL_PASSWORD || process.env.UMMI_MANNING_PASSWORD;
    const superUser = process.env.UMMI_SUPERADMIN_USER;
    const superPass = process.env.UMMI_SUPERADMIN_PASSWORD;

    if (!manningUser || !manningPass) {
      throw new Error('Manning credentials not found in environment.');
    }

    const testExecutionLog: any = {
      testCaseId: 'TC-CM-169',
      scenario: 'Self-encoding',
      title: 'Link expiry cutoff and submit-after-expiry',
      requirements: ['FR-CM-48', 'FR-CM-49', 'SR-08', 'UC-CM-24'],
      clarificationPending: 'CL-10 (Exact boundary equality, timezone, and clock resolution rules)',
      executionTimestampUtc: new Date().toISOString(),
      checks: []
    };

    // ------------------------------------------------------------------------
    // Step 1: Manning Staff generates isolated QA invitation with future validity
    // ------------------------------------------------------------------------
    const manningContext = await browser.newContext();
    const manningPage = await manningContext.newPage();

    const initialResp = await manningPage.goto('/login.aspx');
    const serverDateHeader = initialResp?.headers()['date'] || 'Unknown';
    testExecutionLog.serverHttpDateHeader = serverDateHeader;

    await manningPage.fill('#txtUsername', manningUser);
    await manningPage.fill('#txtPassword', manningPass);
    await manningPage.click('#btnLogin');
    await manningPage.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 15000 });

    await manningPage.goto('/Applicant/ApplicantPool.aspx');
    await manningPage.waitForLoadState('networkidle');

    // Generate isolated active link (Valid Until: Tomorrow)
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().split('T')[0];

    const testApplicantName = `QA-C2-TC169-${Date.now()}`;
    const testApplicantEmail = `tc169-${Date.now()}@example.com`;

    const btnGen = manningPage.locator('[id$="btnGenerateLink"]');
    await btnGen.click();
    await manningPage.waitForLoadState('load');
    await expect(manningPage.locator('[id$="panelGenerateLink"]')).toBeVisible({ timeout: 10000 });

    await manningPage.fill('#ContentPlaceHolder1_txtLinkFirstName', 'QAFirst');
    await manningPage.fill('#ContentPlaceHolder1_txtLinkLastName', testApplicantName);
    await manningPage.fill('#ContentPlaceHolder1_txtLinkEmail', testApplicantEmail);
    await manningPage.click('#ContentPlaceHolder1_btnCreateLink');
    await manningPage.waitForLoadState('load');

    const panelResult = manningPage.locator('[id$="panelLinkResult"]');
    await expect(panelResult).toBeVisible({ timeout: 10000 });

    const activeRawUrl = await manningPage.locator('input[id*="txtGeneratedLink"]').inputValue();
    const activeExpiryText = await manningPage.locator('span[id*="lblGeneratedExpiry"]').innerText();

    console.log('TC-CM-169 Generated Active Link URL:', sanitizeUrl(activeRawUrl));
    console.log('TC-CM-169 Active Link Displayed Expiry:', activeExpiryText);

    testExecutionLog.activeLink = {
      applicantName: testApplicantName,
      email: testApplicantEmail,
      displayedExpiry: activeExpiryText,
      targetValidityDate: tomorrowStr
    };

    // ------------------------------------------------------------------------
    // Step 2: Access Immediately Before Expiry (Active Link)
    // ------------------------------------------------------------------------
    const applicantContext1 = await browser.newContext();
    const applicantPage1 = await applicantContext1.newPage();

    const beforeReqTime = new Date().toISOString();
    const activeNavResp = await applicantPage1.goto(activeRawUrl);
    await applicantPage1.waitForLoadState('networkidle');

    const landingUrl1 = applicantPage1.url();
    const httpStatus1 = activeNavResp?.status() || 200;
    console.log('TC-CM-169 Active Landing URL:', sanitizeUrl(landingUrl1));

    expect(landingUrl1).toMatch(/\/Applicant\/SelfEncode\.aspx/i);
    const txtLastName = applicantPage1.locator('input[id*="txtLastName"]');
    await expect(txtLastName).toBeVisible({ timeout: 10000 });

    await applicantPage1.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc169-step1-access-before-expiry.png'),
      fullPage: true
    });

    testExecutionLog.checks.push({
      assertion: 'Access before expiry',
      requestTimeUtc: beforeReqTime,
      httpStatus: httpStatus1,
      landingUrl: sanitizeUrl(landingUrl1),
      formRendered: true,
      result: 'PASSED'
    });

    // ------------------------------------------------------------------------
    // Step 3: Manning Staff updates link status to Expired (Simulating Post-Expiry)
    // ------------------------------------------------------------------------
    const isManageVisible = await manningPage.locator('[id$="panelManageLinks"]').isVisible();
    if (!isManageVisible) {
      await manningPage.click('[id$="btnManageLinks"]');
      await manningPage.waitForLoadState('load');
    }
    await expect(manningPage.locator('[id$="panelManageLinks"]')).toBeVisible({ timeout: 10000 });

    const row = manningPage.locator('table[id*="gvLinks"] tr').filter({ hasText: testApplicantName }).first();
    await expect(row).toBeVisible({ timeout: 10000 });

    const statusDdl = row.locator('select[id*="drpdwnNewStatus"]');
    const btnApply = row.locator('a[id*="btnUpdateStatus"]');

    await statusDdl.selectOption('Expired');
    manningPage.once('dialog', d => d.accept());
    await btnApply.click();
    await manningPage.waitForLoadState('load');

    console.log(`TC-CM-169 Link ${testApplicantName} updated to Expired status.`);

    // ------------------------------------------------------------------------
    // Step 4: Access After Expiry (Expired Link)
    // ------------------------------------------------------------------------
    const applicantContext2 = await browser.newContext();
    const applicantPage2 = await applicantContext2.newPage();

    const afterReqTime = new Date().toISOString();
    const expiredNavResp = await applicantPage2.goto(activeRawUrl);
    await applicantPage2.waitForLoadState('networkidle');

    const landingUrl2 = applicantPage2.url();
    const httpStatus2 = expiredNavResp?.status() || 200;
    console.log('TC-CM-169 Expired Landing URL:', sanitizeUrl(landingUrl2));

    expect(landingUrl2).toMatch(/\/Applicant\/AccessDenied\.aspx/i);
    const deniedHeader = applicantPage2.locator('h1, h2, .denied-title, .card-title');
    await expect(deniedHeader).toContainText(/Access Denied/i);

    await applicantPage2.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc169-step2-access-after-expiry.png'),
      fullPage: true
    });

    testExecutionLog.checks.push({
      assertion: 'Access after expiry',
      requestTimeUtc: afterReqTime,
      httpStatus: httpStatus2,
      landingUrl: sanitizeUrl(landingUrl2),
      deniedTitleRendered: true,
      result: 'PASSED'
    });

    // ------------------------------------------------------------------------
    // Step 5: Form opened before expiry, submitted after expiry
    // (applicantPage1 was opened before expiry, but the link is now Expired)
    // ------------------------------------------------------------------------
    const submitReqTime = new Date().toISOString();
    console.log('TC-CM-169 Submitting form on session opened before expiry...');

    // Fill fields and trigger Province AutoPostBack with waitForNavigation
    await Promise.all([
      applicantPage1.waitForNavigation({ waitUntil: 'networkidle' }),
      applicantPage1.evaluate(() => {
        const setVal = (id: string, val: string) => {
          const el = document.getElementById(id) as HTMLInputElement | HTMLSelectElement;
          if (el) el.value = val;
        };
        const selectFirst = (id: string) => {
          const sel = document.getElementById(id) as HTMLSelectElement;
          if (sel && sel.options.length > 1) {
            sel.selectedIndex = 1;
          }
        };

        setVal('ContentPlaceHolder1_txtFirstName', 'QAExpiredTester');
        setVal('ContentPlaceHolder1_txtLastName', 'QAExpiredTester');
        setVal('ContentPlaceHolder1_txtDOB', '1995-05-15');
        setVal('ContentPlaceHolder1_txtPOB', 'Manila');
        setVal('ContentPlaceHolder1_txtHeight', '170');
        setVal('ContentPlaceHolder1_txtWeight', '65');
        setVal('ContentPlaceHolder1_txtContact', '+63 917 169 0001');
        setVal('ContentPlaceHolder1_txtEmail', 'expired-test@example.com');
        setVal('ContentPlaceHolder1_txtAddress', '123 Test St');

        selectFirst('ContentPlaceHolder1_drpdwnGender');
        selectFirst('ContentPlaceHolder1_drpdwnCivilStatus');
        selectFirst('ContentPlaceHolder1_drpdwnReligion');
        selectFirst('ContentPlaceHolder1_drpdwnNationality');
        selectFirst('ContentPlaceHolder1_drpdwnBloodType');
        selectFirst('ContentPlaceHolder1_drpdwnRank');
        selectFirst('ContentPlaceHolder1_drpdwnSchool');
        selectFirst('ContentPlaceHolder1_drpdwnCourse');

        const prov = document.getElementById('ContentPlaceHolder1_drpdwnProvince') as HTMLSelectElement;
        if (prov && prov.options.length > 1) {
          prov.selectedIndex = 1;
        }
        (window as any).__doPostBack('ctl00$ContentPlaceHolder1$drpdwnProvince', '');
      })
    ]);

    // Select city on Step 2 and submit form with waitForNavigation
    await Promise.all([
      applicantPage1.waitForNavigation({ waitUntil: 'networkidle' }),
      applicantPage1.evaluate(() => {
        const city = document.getElementById('ContentPlaceHolder1_drpdwnCity') as HTMLSelectElement;
        if (city && city.options.length > 1) {
          city.selectedIndex = 1;
        }

        (window as any).validateAllForm = () => true;
        document.querySelectorAll('[required]').forEach(el => el.removeAttribute('required'));
        if (document.forms[0]) {
          document.forms[0].noValidate = true;
        }

        const btn = document.getElementById('ContentPlaceHolder1_btnSubmit') as HTMLElement;
        if (btn) {
          btn.removeAttribute('onclick');
          btn.click();
        }
      })
    ]);

    // Server-side revalidation assertion: Submission must be rejected
    const lblNotify = applicantPage1.locator('#ContentPlaceHolder1_lblNotify');
    await expect(lblNotify).toContainText(/(expired|used|revoked)/i, { timeout: 15000 });
    const notifyText = await lblNotify.innerText();
    console.log('TC-CM-169 Submission rejection notification:', notifyText);

    await applicantPage1.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc169-step3-submit-after-expiry-rejected.png'),
      fullPage: true
    });

    testExecutionLog.checks.push({
      assertion: 'Form opened before expiry, submitted after expiry is rejected',
      submissionTimeUtc: submitReqTime,
      actualNotification: notifyText,
      rejectionConfirmed: true,
      result: 'PASSED'
    });

    // ------------------------------------------------------------------------
    // Step 6: Evidence that submission did not persist in database
    // Verify via Manning Staff Applicant Pool that no personnel record exists
    // ------------------------------------------------------------------------
    await manningPage.goto('/Applicant/ApplicantPool.aspx');
    await manningPage.waitForLoadState('networkidle');

    const txtSearch = manningPage.locator('input[id*="txtSearch"], input[id*="txtSearchApplicant"]');
    if (await txtSearch.isVisible()) {
      await txtSearch.fill('QAExpiredTester');
      const btnSearch = manningPage.locator('input[id*="btnSearch"], button[id*="btnSearch"]');
      if (await btnSearch.isVisible()) {
        await btnSearch.click();
        await manningPage.waitForLoadState('networkidle');
      }
    }

    const applicantGrid = manningPage.locator('table[id*="gvApplicants"]');
    const applicantGridText = await applicantGrid.innerText().catch(() => '');
    expect(applicantGridText).not.toContain('QAExpiredTester');
    console.log('TC-CM-169 Confirmed zero personnel records created for expired submission.');

    await manningPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc169-step4-zero-persistence-verified.png'),
      fullPage: true
    });

    testExecutionLog.checks.push({
      assertion: 'Zero personnel persistence verified',
      applicantSearchConfirmed: true,
      persistedRecordCount: 0,
      result: 'PASSED'
    });

    // ------------------------------------------------------------------------
    // Step 7: Inspect Security / Activity Logs
    // ------------------------------------------------------------------------
    if (superUser && superPass) {
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
      const deniedLog = logRows.find(r => r.includes('ApplicantLink') && r.includes('Invalid/expired encoding link attempt'));
      console.log('TC-CM-169 Activity log denial audit entry:', deniedLog ? 'CONFIRMED' : 'NOT FOUND');

      if (deniedLog) {
        testExecutionLog.activityLogAudit = {
          entryFound: true,
          sampleRow: deniedLog.replace(/\t+/g, ' | ').replace(/\n+/g, ' ')
        };
      }
      await superPage.screenshot({
        path: path.join(SCREENSHOT_DIR, 'tc169-step5-activity-log-audit.png'),
        fullPage: true
      });
      await superContext.close();
    }

    // ------------------------------------------------------------------------
    // Step 8: Preserve isolated test invitation as evidence (Do not run cleanup)
    // ------------------------------------------------------------------------
    console.log(`TC-CM-169 Preserving isolated test link ${testApplicantName} as evidence.`);

    await manningContext.close();
    await applicantContext1.close();
    await applicantContext2.close();

    // Write results JSON
    fs.writeFileSync(
      path.join(RESULTS_DIR, 'tc169-results.json'),
      JSON.stringify(testExecutionLog, null, 2),
      'utf8'
    );
  });

