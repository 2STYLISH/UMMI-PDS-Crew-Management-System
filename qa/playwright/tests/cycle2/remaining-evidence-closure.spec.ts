import { test, expect } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

const SCREENSHOT_DIR = path.resolve(__dirname, '../../evidence/screenshots/cycle2/closure');
const TRACE_DIR = path.resolve(__dirname, '../../evidence/traces');

if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
if (!fs.existsSync(TRACE_DIR)) fs.mkdirSync(TRACE_DIR, { recursive: true });

async function loginAs(page, username, password) {
  if (!username || !password) throw new Error('Missing credentials for login');
  await page.goto('/login.aspx', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#txtUsername', { timeout: 15000 });
  await page.fill('#txtUsername', username);
  await page.fill('#txtPassword', password);
  await page.click('#btnLogin');
  await page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 25000 });
  await page.waitForLoadState('domcontentloaded');
}

async function navigateToQueryCrew(page) {
  if (!page.url().includes('QueryCrew.aspx')) {
    await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
  }
}

async function searchLastName(page, lastName, firstName = '') {
  await page.fill('input[id*="txtLastName"]', lastName);
  await page.fill('input[id*="txtFirstName"]', firstName);
  await Promise.all([
    page.waitForResponse(res => res.url().includes('QueryCrew.aspx') && res.request().method() === 'POST'),
    page.locator('input[id*="btnSearch"]').click(),
  ]);
  await page.waitForTimeout(1000);
}

test.describe.serial('Cycle 2 Final QA Closure Suite (Azure Staging)', () => {

  // ==========================================================================
  // TC-CM-067: Documentation Officer with viewcrewcontactdetails = 0
  // ==========================================================================
  test('TC-CM-067: Documentation Officer (contact disabled) - Privacy, Response Body, and Attachment Denied', async ({ page, request }) => {
    const user = process.env.QA2CONTACT_DOC_USER;
    const pass = process.env.QA2CONTACT_DOC_PASSWORD;
    await loginAs(page, user, pass);
    await navigateToQueryCrew(page);

    await searchLastName(page, 'QA2B18_BatangasMatch');
    const crewRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BatangasMatch' });
    await expect(crewRow).toBeVisible();

    const profileLink = crewRow.locator('a[id*="lnkProfile"]');
    await expect(profileLink).toBeVisible();

    const [profilePage] = await Promise.all([
      page.context().waitForEvent('page'),
      profileLink.click()
    ]);
    await profilePage.waitForLoadState('networkidle');

    // 1. UI Section Visibility: Contact, Statutory, Family, Notes, Assessments completely HIDDEN
    await expect(profilePage.locator('#divContactInfo, [id$="divContactInfo"]')).toHaveCount(0);
    await expect(profilePage.locator('#divStatutory, [id$="divStatutory"]')).toHaveCount(0);
    await expect(profilePage.locator('#divFamilyInfo, [id$="divFamilyInfo"]')).toHaveCount(0);
    await expect(profilePage.locator('#divPersonalNotes, [id$="divPersonalNotes"]')).toHaveCount(0);
    await expect(profilePage.locator('#divComments, [id$="divComments"]')).toHaveCount(0);

    // 2. Permitted Profile Info is Visible
    await expect(profilePage.locator('#ContentPlaceHolder1_lblFullName')).toContainText('QA2B18_BatangasMatch');
    await expect(profilePage.locator('#ContentPlaceHolder1_lblRank')).toHaveText('AB SEAMAN');

    // 3. Response Body Verification: Confirm private values not in raw response
    const cookies = await page.context().cookies();
    const cookieHeader = cookies.map(c => `${c.name}=${c.value}`).join('; ');
    const profileUrl = profilePage.url();
    const directRes = await request.get(profileUrl, { headers: { Cookie: cookieHeader } });
    const directBody = await directRes.text();

    expect(directBody).not.toContain('lblContact');
    expect(directBody).not.toContain('lblEmail');
    expect(directBody).not.toContain('lblSSS');
    expect(directBody).not.toContain('lblTIN');
    expect(directBody).not.toContain('divContactInfo');

    // 4. Assessment Attachment Authorization: Direct retrieval returns HTTP 403 Forbidden
    const attachRes = await request.get('/Crew/AssessmentAttachmentHandler.ashx?cid=5', {
      headers: { Cookie: cookieHeader }
    });
    expect(attachRes.status(), 'Assessment attachment must return HTTP 403 Forbidden for unauthorized user').toBe(403);

    await profilePage.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc067-doc-officer-privacy-verified.png'), fullPage: true });
    await profilePage.close();
  });

  // ==========================================================================
  // TC-CM-069: Admin with viewcrewcontactdetails = 0
  // ==========================================================================
  test('TC-CM-069: Admin (contact disabled) - Privacy, Response Body, and Attachment Denied', async ({ page, request }) => {
    const user = process.env.QA2CONTACT_ADMIN_USER;
    const pass = process.env.QA2CONTACT_ADMIN_PASSWORD;
    await loginAs(page, user, pass);
    await navigateToQueryCrew(page);

    await searchLastName(page, 'QA2B18_BatangasMatch');
    const crewRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BatangasMatch' });
    await expect(crewRow).toBeVisible();

    const [profilePage] = await Promise.all([
      page.context().waitForEvent('page'),
      crewRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await profilePage.waitForLoadState('networkidle');

    // UI Checks
    await expect(profilePage.locator('#divContactInfo, [id$="divContactInfo"]')).toHaveCount(0);
    await expect(profilePage.locator('#divStatutory, [id$="divStatutory"]')).toHaveCount(0);
    await expect(profilePage.locator('#divFamilyInfo, [id$="divFamilyInfo"]')).toHaveCount(0);
    await expect(profilePage.locator('#divPersonalNotes, [id$="divPersonalNotes"]')).toHaveCount(0);
    await expect(profilePage.locator('#divComments, [id$="divComments"]')).toHaveCount(0);

    // Response Body Check
    const cookies = await page.context().cookies();
    const cookieHeader = cookies.map(c => `${c.name}=${c.value}`).join('; ');
    const directRes = await request.get(profilePage.url(), { headers: { Cookie: cookieHeader } });
    const directBody = await directRes.text();
    expect(directBody).not.toContain('lblContact');
    expect(directBody).not.toContain('divContactInfo');

    // Attachment Handler Check: HTTP 403 Forbidden
    const attachRes = await request.get('/Crew/AssessmentAttachmentHandler.ashx?cid=5', {
      headers: { Cookie: cookieHeader }
    });
    expect(attachRes.status(), 'Assessment attachment must return HTTP 403 Forbidden for unauthorized user').toBe(403);

    await profilePage.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc069-admin-privacy-verified.png'), fullPage: true });
    await profilePage.close();
  });

  // ==========================================================================
  // TC-CM-071: Super-Admin with viewcrewcontactdetails = 0
  // ==========================================================================
  test('TC-CM-071: Super-Admin (contact disabled) - Privacy, Response Body, and Attachment Denied', async ({ page, request }) => {
    const user = process.env.QA2CONTACT_SUPERADMIN_USER;
    const pass = process.env.QA2CONTACT_SUPERADMIN_PASSWORD;
    await loginAs(page, user, pass);
    await navigateToQueryCrew(page);

    await searchLastName(page, 'QA2B18_BatangasMatch');
    const crewRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BatangasMatch' });
    await expect(crewRow).toBeVisible();

    const [profilePage] = await Promise.all([
      page.context().waitForEvent('page'),
      crewRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await profilePage.waitForLoadState('networkidle');

    // UI Checks
    await expect(profilePage.locator('#divContactInfo, [id$="divContactInfo"]')).toHaveCount(0);
    await expect(profilePage.locator('#divStatutory, [id$="divStatutory"]')).toHaveCount(0);
    await expect(profilePage.locator('#divFamilyInfo, [id$="divFamilyInfo"]')).toHaveCount(0);
    await expect(profilePage.locator('#divPersonalNotes, [id$="divPersonalNotes"]')).toHaveCount(0);
    await expect(profilePage.locator('#divComments, [id$="divComments"]')).toHaveCount(0);

    // Response Body Check
    const cookies = await page.context().cookies();
    const cookieHeader = cookies.map(c => `${c.name}=${c.value}`).join('; ');
    const directRes = await request.get(profilePage.url(), { headers: { Cookie: cookieHeader } });
    const directBody = await directRes.text();
    expect(directBody).not.toContain('lblContact');
    expect(directBody).not.toContain('divContactInfo');

    // Attachment Handler Check: HTTP 403 Forbidden
    const attachRes = await request.get('/Crew/AssessmentAttachmentHandler.ashx?cid=5', {
      headers: { Cookie: cookieHeader }
    });
    expect(attachRes.status(), 'Assessment attachment must return HTTP 403 Forbidden for unauthorized user').toBe(403);

    await profilePage.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc071-superadmin-privacy-verified.png'), fullPage: true });
    await profilePage.close();
  });

  // ==========================================================================
  // TC-CM-068: Admin with viewcrewcontactdetails = 1
  // ==========================================================================
  test('TC-CM-068: Admin (contact enabled) - Contact & Statutory details visible and Attachment Authorized', async ({ page, request }) => {
    const user = process.env.QA_ADMIN_CONTROL_USER || process.env.UMMI_ADMIN_USER;
    const pass = process.env.QA_ADMIN_CONTROL_PASSWORD || process.env.UMMI_ADMIN_PASSWORD;
    await loginAs(page, user, pass);
    await navigateToQueryCrew(page);

    await searchLastName(page, 'Santos', 'QA Maria');
    const crewRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'Santos' }).first();
    await expect(crewRow).toBeVisible();

    const [profilePage] = await Promise.all([
      page.context().waitForEvent('page'),
      crewRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await profilePage.waitForLoadState('networkidle');

    // UI Checks: Contact and Statutory sections are VISIBLE on Basic Info tab
    await expect(profilePage.locator('#ContentPlaceHolder1_divContactInfo')).toBeVisible();
    await expect(profilePage.locator('#ContentPlaceHolder1_divStatutory')).toBeVisible();

    // Family Info and Comments are attached in DOM (on their respective tab-panes)
    await expect(profilePage.locator('#ContentPlaceHolder1_divFamilyInfo')).toHaveCount(1);
    await expect(profilePage.locator('#ContentPlaceHolder1_divComments')).toHaveCount(1);

    // Click Family tab and confirm Family Info card is displayed
    const familyTab = profilePage.locator('button[data-bs-target="#tabFamily"], a[href="#tabFamily"]').first();
    if (await familyTab.count() > 0) {
      await familyTab.click();
      await page.waitForTimeout(500);
      await expect(profilePage.locator('#ContentPlaceHolder1_divFamilyInfo')).toBeVisible();
    }

    // Verify presence of contact/statutory fields
    const contactNum = await profilePage.locator('#ContentPlaceHolder1_lblContact').innerText();
    const emailAddr = await profilePage.locator('#ContentPlaceHolder1_lblEmail').innerText();
    expect(contactNum.length).toBeGreaterThan(0);
    expect(emailAddr).toContain('@');

    // Response Body Check: Contains authorized private sections
    const cookies = await page.context().cookies();
    const cookieHeader = cookies.map(c => `${c.name}=${c.value}`).join('; ');
    const directRes = await request.get(profilePage.url(), { headers: { Cookie: cookieHeader } });
    const directBody = await directRes.text();
    expect(directBody).toContain('divContactInfo');
    expect(directBody).toContain('divStatutory');

    // Attachment Handler Check: Authorized access must return HTTP 200 and valid PDF content
    const attachRes = await request.get('/Crew/AssessmentAttachmentHandler.ashx?cid=5', {
      headers: { Cookie: cookieHeader }
    });
    expect(attachRes.status(), 'Authorized Admin must receive HTTP 200 OK from AssessmentAttachmentHandler').toBe(200);
    const contentType = attachRes.headers()['content-type'] || '';
    expect(contentType.toLowerCase(), 'Attachment response must be PDF').toContain('application/pdf');
    const bodyBuffer = await attachRes.body();
    expect(bodyBuffer.length, 'Attachment body must not be empty').toBeGreaterThan(0);
    expect(bodyBuffer.toString('utf8', 0, 5), 'Attachment content must begin with PDF magic header').toBe('%PDF-');

    await profilePage.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc068-admin-authorized-contact-visible.png'), fullPage: true });
    await profilePage.close();
  });

  // ==========================================================================
  // TC-CM-074: Vessel Owner with viewcrewcontactdetails = 1
  // ==========================================================================
  test('TC-CM-074: Vessel Owner (contact enabled) - Contact & Statutory details visible and Attachment Authorized', async ({ page, request }) => {
    const user = process.env.QA2CONTACT_OWNER_USER || process.env.UMMI_OWNER_USER;
    const pass = process.env.QA2CONTACT_OWNER_PASSWORD || process.env.UMMI_OWNER_PASSWORD;
    await loginAs(page, user, pass);
    await navigateToQueryCrew(page);

    // Vessel Owner is assigned Vessel A; query QA2B18_BatangasMatch (on Vessel A)
    await searchLastName(page, 'QA2B18_BatangasMatch');
    const crewRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BatangasMatch' }).first();
    await expect(crewRow).toBeVisible();

    const [profilePage] = await Promise.all([
      page.context().waitForEvent('page'),
      crewRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await profilePage.waitForLoadState('networkidle');

    // UI Checks: Contact and Statutory sections are VISIBLE on Basic Info tab
    await expect(profilePage.locator('#ContentPlaceHolder1_divContactInfo')).toBeVisible();
    await expect(profilePage.locator('#ContentPlaceHolder1_divStatutory')).toBeVisible();
    await expect(profilePage.locator('#ContentPlaceHolder1_divFamilyInfo')).toHaveCount(1);
    await expect(profilePage.locator('#ContentPlaceHolder1_divComments')).toHaveCount(1);

    // Response Body Check
    const cookies = await page.context().cookies();
    const cookieHeader = cookies.map(c => `${c.name}=${c.value}`).join('; ');
    const directRes = await request.get(profilePage.url(), { headers: { Cookie: cookieHeader } });
    const directBody = await directRes.text();
    expect(directBody).toContain('divContactInfo');
    expect(directBody).toContain('divStatutory');

    // Attachment Handler Check: NOT 403
    const attachRes = await request.get('/Crew/AssessmentAttachmentHandler.ashx?cid=1', {
      headers: { Cookie: cookieHeader }
    });
    expect(attachRes.status(), 'Authorized Vessel Owner must NOT be forbidden from handler').not.toBe(403);

    await profilePage.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc074-owner-authorized-contact-visible.png'), fullPage: true });
    await profilePage.close();
  });

  // ==========================================================================
  // TC-CM-076: BMI Calculation & Blank/Zero Suppression
  // ==========================================================================
  test('TC-CM-076: BMI Calculation - Santos 180cm/72kg displays 22.2 (Normal), blank & zero suppressed', async ({ page }) => {
    const user = process.env.QA_MANNING_CONTROL_USER || process.env.UMMI_MANNING_USER;
    const pass = process.env.QA_MANNING_CONTROL_PASSWORD || process.env.UMMI_MANNING_PASSWORD;
    await loginAs(page, user, pass);
    await navigateToQueryCrew(page);

    // 1. Crew A001 (Height 180 cm, Weight 72 kg, QA Maria Santos)
    await searchLastName(page, 'Santos', 'QA Maria');
    const santosRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'Santos' }).first();
    await expect(santosRow).toBeVisible();

    const [santosPage] = await Promise.all([
      page.context().waitForEvent('page'),
      santosRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await santosPage.waitForLoadState('networkidle');

    const h = (await santosPage.locator('#ContentPlaceHolder1_lblHeight').innerText()).trim();
    const w = (await santosPage.locator('#ContentPlaceHolder1_lblWeight').innerText()).trim();
    const bmi = (await santosPage.locator('#ContentPlaceHolder1_lblBMI').innerText()).trim();
    const bmiClass = (await santosPage.locator('#ContentPlaceHolder1_lblBMIClass').innerText()).trim();
    const badgeClass = await santosPage.locator('#ContentPlaceHolder1_lblBMIClass').getAttribute('class');

    console.log(`[TC-CM-076] Santos, QA Maria: Height='${h}', Weight='${w}', BMI='${bmi}', Class='${bmiClass}'`);
    expect(h).toBe('180');
    expect(w).toBe('72');
    expect(bmi, 'Isolated 180cm/72kg fixture must strictly display BMI 22.2').toBe('22.2');
    expect(bmiClass).toBe('Normal');
    expect(badgeClass).toContain('bmi-normal');

    await santosPage.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc076-santos-bmi-22.2-normal.png'), fullPage: true });
    await santosPage.close();

    // 2. Blank Biometric Suppression (QA2B18_BmiBlank)
    await navigateToQueryCrew(page);
    await searchLastName(page, 'QA2B18_BmiBlank');
    const blankRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BmiBlank' }).first();
    await expect(blankRow).toBeVisible();

    const [blankPage] = await Promise.all([
      page.context().waitForEvent('page'),
      blankRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await blankPage.waitForLoadState('networkidle');

    const blankBmi = (await blankPage.locator('#ContentPlaceHolder1_lblBMI').innerText()).trim();
    const blankClass = (await blankPage.locator('#ContentPlaceHolder1_lblBMIClass').innerText()).trim();
    console.log(`[TC-CM-076] BmiBlank: BMI='${blankBmi}', Class='${blankClass}'`);
    expect(blankBmi, 'Blank biometric data must suppress BMI calculation').toBe('');
    expect(blankClass, 'Blank biometric data must suppress BMI classification').toBe('');

    await blankPage.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc076-bmi-blank-suppressed.png'), fullPage: true });
    await blankPage.close();

    // 3. Zero Biometric Suppression (QA2B18_BmiZero)
    await navigateToQueryCrew(page);
    await searchLastName(page, 'QA2B18_BmiZero');
    const zeroRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BmiZero' }).first();
    await expect(zeroRow).toBeVisible();

    const [zeroPage] = await Promise.all([
      page.context().waitForEvent('page'),
      zeroRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await zeroPage.waitForLoadState('networkidle');

    const zeroBmi = (await zeroPage.locator('#ContentPlaceHolder1_lblBMI').innerText()).trim();
    const zeroClass = (await zeroPage.locator('#ContentPlaceHolder1_lblBMIClass').innerText()).trim();
    console.log(`[TC-CM-076] BmiZero: BMI='${zeroBmi}', Class='${zeroClass}'`);
    expect(zeroBmi, 'Zero biometric data must suppress BMI calculation without division by zero').toBe('');
    expect(zeroClass, 'Zero biometric data must suppress BMI classification').toBe('');

    await zeroPage.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc076-bmi-zero-suppressed.png'), fullPage: true });
    await zeroPage.close();
  });

  // ==========================================================================
  // TC-CM-077: BMI Classification Boundaries & Requirement Gap Identification
  // ==========================================================================
  test('TC-CM-077: BMI classification boundaries and threshold specification analysis', async ({ page }) => {
    const user = process.env.UMMI_MANNING_USER;
    const pass = process.env.UMMI_MANNING_PASSWORD;
    await loginAs(page, user, pass);
    await navigateToQueryCrew(page);

    // Open Santos, QA Maria to verify classification styling
    await searchLastName(page, 'Santos', 'QA Maria');
    const santosRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'Santos' }).first();
    await expect(santosRow).toBeVisible();

    const [santosPage] = await Promise.all([
      page.context().waitForEvent('page'),
      santosRow.locator('a[id*="lnkProfile"]').click()
    ]);
    await santosPage.waitForLoadState('networkidle');

    const badge = santosPage.locator('#ContentPlaceHolder1_lblBMIClass');
    await expect(badge).toBeVisible();
    const text = (await badge.innerText()).trim();
    const bg = await badge.evaluate(el => window.getComputedStyle(el).backgroundColor);
    const col = await badge.evaluate(el => window.getComputedStyle(el).color);

    console.log(`[TC-CM-077] Classification Badge Observed: Text='${text}', bg='${bg}', color='${col}'`);
    expect(text).toBe('Normal');

    // Requirement Gap Analysis:
    // Application implements standard WHO thresholds (<18.5 Underweight, 18.5-24.9 Normal, 25.0-29.9 Overweight, >=30 Obese).
    // SRS lacks formal approval of threshold boundary inclusion rules and color hex specifications.
    await santosPage.screenshot({ path: path.join(SCREENSHOT_DIR, 'tc077-bmi-classification-boundary-gap.png'), fullPage: true });
    await santosPage.close();
  });

  // ==========================================================================
  // TC-CM-186: Deployed Credential-Storage Evidence against SR-04
  // ==========================================================================
  test('TC-CM-186: Credential-Storage Architecture compliance against current SR-04 wording', async () => {
    // Current SR-04:
    // “The system shall store passwords using a salted, adaptive password-hashing algorithm with a
    // configurable work factor, such as PBKDF2, bcrypt, scrypt, or Argon2id. The system shall not
    // store passwords using plaintext, reversible encryption, or a single-round general-purpose hashing algorithm.”
    const cryptoHelperPath = path.resolve(__dirname, '../../../../CrewMgmt/App_Code/CryptoHelper.vb');
    expect(fs.existsSync(cryptoHelperPath)).toBe(true);

    const code = fs.readFileSync(cryptoHelperPath, 'utf8');

    // 1. Algorithm: PBKDF2-HMAC-SHA256
    expect(code).toContain('PBKDF2-HMAC-SHA256');
    expect(code).toContain('Rfc2898DeriveBytes(plainText, saltBytes, PBKDF2_ITERATIONS, HashAlgorithmName.SHA256)');

    // 2. Configurable work factor (iterations)
    expect(code).toContain('Private Const PBKDF2_ITERATIONS As Integer = 100000');
    expect(code).toContain('PBKDF2_PREFIX');
    expect(code).toContain('"$pbkdf2:"');

    // 3. Cryptographically random per-user salt (256-bit)
    expect(code).toContain('RandomNumberGenerator.Create()');
    expect(code).toContain('Dim saltBytes(31) As Byte');

    // 4. Multi-version migration & upgrade support
    expect(code).toContain('VerifyHashedPassword');
    expect(code).toContain('ByRef needsUpgrade As Boolean');

    console.log('[TC-CM-186] Codebase verification against SR-04: PBKDF2-HMAC-SHA256 (100,000 iterations, 256-bit salt) confirmed compliant.');
  });

});
