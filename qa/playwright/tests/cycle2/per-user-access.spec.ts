import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

const SCREENSHOT_DIR = path.resolve(__dirname, '../../evidence/screenshots/cycle2/per_user_access');
const TRACE_DIR = path.resolve(__dirname, '../../evidence/traces');

if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
if (!fs.existsSync(TRACE_DIR)) fs.mkdirSync(TRACE_DIR, { recursive: true });

// Load credentials directly from .env
const envPath = path.resolve(__dirname, '../../.env');
if (fs.existsSync(envPath)) {
  const content = fs.readFileSync(envPath, 'utf8');
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx === -1) continue;
    const key = trimmed.slice(0, eqIdx).trim();
    let val = trimmed.slice(eqIdx + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    process.env[key] = val;
  }
}

// Credentials from .env
const SUPERADMIN_USER = process.env.UMMI_SUPERADMIN_USER || 'demo.superadmin';
const SUPERADMIN_PASS = process.env.UMMI_SUPERADMIN_PASSWORD || 'password123';


const MANNING_RESTRICTED_USER = process.env.QA_C2_MANNING_RESTRICTED_USER || 'qa.c2.20261001.manning.restricted';
const MANNING_RESTRICTED_PASS = process.env.QA_C2_MANNING_RESTRICTED_PASSWORD || 'C2Manning2026Test';
const MANNING_CONTROL_USER = process.env.QA_MANNING_CONTROL_USER || 'qa.manning.control';
const MANNING_CONTROL_PASS = process.env.QA_MANNING_CONTROL_PASSWORD || '';

const DOC_RESTRICTED_USER = process.env.QA2CONTACT_DOC_USER || 'qa2contact.doc.restricted';
const DOC_RESTRICTED_PASS = process.env.QA2CONTACT_DOC_PASSWORD || '';
const DOC_CONTROL_USER = process.env.QA_DOC_CONTROL_USER || 'qa.doc.control';
const DOC_CONTROL_PASS = process.env.QA_DOC_CONTROL_PASSWORD || '';

const ADMIN_RESTRICTED_USER = process.env.QA2CONTACT_ADMIN_USER || 'qa2contact.admin.restricted';
const ADMIN_RESTRICTED_PASS = process.env.QA2CONTACT_ADMIN_PASSWORD || '';
const ADMIN_CONTROL_USER = process.env.QA_ADMIN_CONTROL_USER || 'qa.admin.control';
const ADMIN_CONTROL_PASS = process.env.QA_ADMIN_CONTROL_PASSWORD || '';

const SUPERADMIN_RESTRICTED_USER = process.env.QA2CONTACT_SUPERADMIN_USER || 'qa2contact.superadmin.restricted';
const SUPERADMIN_RESTRICTED_PASS = process.env.QA2CONTACT_SUPERADMIN_PASSWORD || '';

async function login(page, username, password) {
  if (!username || !password) throw new Error(`Missing credentials for ${username}`);
  await page.context().clearCookies();
  await page.goto('/login.aspx', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#txtUsername', { timeout: 20000 });
  await page.fill('#txtUsername', username);
  await page.fill('#txtPassword', password);
  await Promise.all([
    page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 35000 }),
    page.click('#btnLogin')
  ]);
  await page.waitForLoadState('domcontentloaded');
}


async function configureUserAccess(page, targetUser, allowCrewSearch, allowApplicantPool) {
  await page.goto('/Settings/UserAccounts.aspx', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(1000);
  await page.fill('#ContentPlaceHolder1_txtSearch', targetUser);
  await page.click('#ContentPlaceHolder1_btnSearch');
  await page.waitForTimeout(1500);

  const row = page.locator(`table[id*="gvUsers"] tr:has-text("${targetUser}")`).first();
  await expect(row).toBeVisible();
  await row.locator('a:has-text("Manage")').click();
  await page.waitForTimeout(1500);

  if (allowCrewSearch) {
    await page.check('#ContentPlaceHolder1_chkAllowCrewSearch');
  } else {
    await page.uncheck('#ContentPlaceHolder1_chkAllowCrewSearch');
  }

  if (allowApplicantPool) {
    await page.check('#ContentPlaceHolder1_chkAllowApplicantPool');
  } else {
    await page.uncheck('#ContentPlaceHolder1_chkAllowApplicantPool');
  }

  await page.click('#ContentPlaceHolder1_btnSave');
  await page.waitForTimeout(2000);
}

async function verifyAuditLog(page, targetPagePath) {
  await page.goto('/Settings/ActivityLogs.aspx', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(1000);
  await page.selectOption('select[id*="drpdwnCategory"]', 'Security');
  await page.click('input[id*="btnSearch"]');
  await page.waitForTimeout(1500);

  const logRows = await page.locator('table[id*="gvLogs"] tr').allInnerTexts();
  const found = logRows.some(r => r.includes(`Attempted to access restricted page ${targetPagePath}`));
  return { found, logRows: logRows.slice(0, 5) };
}

test.describe.serial('Cycle 2: Per-User Access Controls on Azure Staging', () => {

  // ==========================================================================
  // Pre-test: Verify Live Deployed Implementation & Build Marker
  // ==========================================================================
  test('Verify Staging Serves New Per-User Access Implementation', async ({ browser }) => {
    const page = await browser.newPage();
    let siteAssetHeader = '';
    let etag = '';

    page.on('response', res => {
      if (res.url().includes('site.css') || res.url().includes('site.js')) {
        siteAssetHeader = res.headers()['last-modified'] || '';
        etag = res.headers()['etag'] || '';
      }
    });

    await login(page, SUPERADMIN_USER, SUPERADMIN_PASS);

    // Verify User Accounts link in nav for Super-Admin
    const userAccountsNav = page.locator('a[href*="UserAccounts.aspx"]');
    await expect(userAccountsNav).toHaveCount(1);
    await page.click('button:has-text("Administration")');
    await expect(userAccountsNav).toBeVisible();

    // Verify UserAccounts.aspx page renders
    const res = await page.goto('/Settings/UserAccounts.aspx', { waitUntil: 'domcontentloaded' });
    expect(res?.status()).toBe(200);

    const title = await page.title();
    expect(title).toContain('User Accounts');

    console.log(`[DEPLOYED BUILD MARKER] Last-Modified: ${siteAssetHeader} | ETag: ${etag} | Title: ${title}`);

    await page.screenshot({
      path: path.join(SCREENSHOT_DIR, 'staging-useraccounts-overview.png'),
      fullPage: true,
    });

    await page.close();
  });

  // ==========================================================================
  // Pre-test: Confirm Isolated Control Accounts Baseline Access
  // ==========================================================================
  test('Confirm Isolated Control Accounts Baseline Access', async ({ browser }) => {
    const controls = [
      { name: 'Manning Staff Control', user: MANNING_CONTROL_USER, pass: MANNING_CONTROL_PASS, prefix: 'manning' },
      { name: 'Documentation Officer Control', user: DOC_CONTROL_USER, pass: DOC_CONTROL_PASS, prefix: 'doc' },
      { name: 'Admin Control', user: ADMIN_CONTROL_USER, pass: ADMIN_CONTROL_PASS, prefix: 'admin' },
    ];

    for (const ctrl of controls) {
      const context = await browser.newContext();
      const page = await context.newPage();

      await login(page, ctrl.user, ctrl.pass);

      const navCrew = await page.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
      const navApp = await page.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
      expect(navCrew).toBeGreaterThan(0);
      expect(navApp).toBeGreaterThan(0);

      const crewRes = await page.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
      expect(page.url()).toContain('QueryCrew.aspx');
      expect(await page.title()).toContain('Crew Search');

      const appRes = await page.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
      expect(page.url()).toContain('ApplicantPool.aspx');
      expect(await page.title()).toContain('Applicant Pool');

      await page.screenshot({
        path: path.join(SCREENSHOT_DIR, `control-baseline-${ctrl.prefix}-access.png`),
      });

      console.log(`[CONTROL BASELINE VERIFIED]: ${ctrl.name} (${ctrl.user}) has full access to both features.`);
      await context.close();
    }
  });

  // ==========================================================================
  // TC-CM-002: Manning Staff with Crew Search disabled
  // ==========================================================================
  test('TC-CM-002: Manning Staff with Crew Search disabled', async ({ browser }) => {
    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();
    await adminContext.tracing.start({ screenshots: true, snapshots: true });

    // Step 1 & 2: Configure qa.c2.20261001.manning.restricted -> CrewSearch = false, ApplicantPool = true
    await login(adminPage, SUPERADMIN_USER, SUPERADMIN_PASS);
    await configureUserAccess(adminPage, MANNING_RESTRICTED_USER, false, true);

    await adminPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc002-manning-crewsearch-disabled-config.png'),
    });

    // Step 3: Sign in as restricted user
    const userContext = await browser.newContext();
    const userPage = await userContext.newPage();
    await login(userPage, MANNING_RESTRICTED_USER, MANNING_RESTRICTED_PASS);

    // Step 4: Assert Crew Search menu link is hidden and direct access denied
    const navCrewLinks = await userPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(navCrewLinks).toBe(0);

    const directCrew = await userPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('Home.aspx'); // Redirected to dashboard
    expect(await userPage.title()).toContain('Dashboard');

    await userPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc002-manning-crewsearch-denied-redirect.png'),
    });

    // Step 5: Assert other feature (Applicant Pool) is allowed
    const navAppLinks = await userPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(navAppLinks).toBeGreaterThan(0);
    const directApp = await userPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('ApplicantPool.aspx');
    expect(await userPage.title()).toContain('Applicant Pool');

    // Step 6: Control user of same role keeps full access
    const controlContext = await browser.newContext();
    const controlPage = await controlContext.newPage();
    await login(controlPage, MANNING_CONTROL_USER, MANNING_CONTROL_PASS);
    
    const ctrlCrewNav = await controlPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(ctrlCrewNav).toBeGreaterThan(0);
    const ctrlAppNav = await controlPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(ctrlAppNav).toBeGreaterThan(0);

    const controlCrew = await controlPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('QueryCrew.aspx');
    expect(await controlPage.title()).toContain('Crew Search');

    const controlApp = await controlPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('ApplicantPool.aspx');
    expect(await controlPage.title()).toContain('Applicant Pool');

    await controlPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc002-manning-control-access.png'),
    });

    // Step 7: Inspect denial audit entry
    const auditRes = await verifyAuditLog(adminPage, '/Crew/QueryCrew.aspx');
    expect(auditRes.found).toBe(true);
    console.log('[TC-CM-002 Audit Entry Verified]:', auditRes.logRows[0]);

    // Step 8: Restore settings and verify restored access
    await configureUserAccess(adminPage, MANNING_RESTRICTED_USER, true, true);

    const restoredContext = await browser.newContext();
    const restoredPage = await restoredContext.newPage();
    await login(restoredPage, MANNING_RESTRICTED_USER, MANNING_RESTRICTED_PASS);

    const rCrewNav = await restoredPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(rCrewNav).toBeGreaterThan(0);
    const rAppNav = await restoredPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(rAppNav).toBeGreaterThan(0);

    await restoredPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('QueryCrew.aspx');
    expect(await restoredPage.title()).toContain('Crew Search');

    await restoredPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('ApplicantPool.aspx');
    expect(await restoredPage.title()).toContain('Applicant Pool');

    await restoredPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc002-manning-restored-access.png'),
    });
    await restoredContext.close();

    await adminContext.tracing.stop({ path: path.join(TRACE_DIR, 'tc002-trace.zip') });
    await userContext.close();
    await controlContext.close();
    await adminContext.close();
  });

  // ==========================================================================
  // TC-CM-004: Manning Staff with Applicant Pool disabled
  // ==========================================================================
  test('TC-CM-004: Manning Staff with Applicant Pool disabled', async ({ browser }) => {
    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();
    await adminContext.tracing.start({ screenshots: true, snapshots: true });

    // Step 1 & 2: Configure qa.c2.20261001.manning.restricted -> CrewSearch = true, ApplicantPool = false
    await login(adminPage, SUPERADMIN_USER, SUPERADMIN_PASS);
    await configureUserAccess(adminPage, MANNING_RESTRICTED_USER, true, false);

    await adminPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc004-manning-applicantpool-disabled-config.png'),
    });

    // Step 3: Sign in as restricted user
    const userContext = await browser.newContext();
    const userPage = await userContext.newPage();
    await login(userPage, MANNING_RESTRICTED_USER, MANNING_RESTRICTED_PASS);

    // Step 4: Assert Applicant Pool menu link is hidden and direct access denied
    const navAppLinks = await userPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(navAppLinks).toBe(0);

    const directApp = await userPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('Home.aspx');
    expect(await userPage.title()).toContain('Dashboard');

    await userPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc004-manning-applicantpool-denied-redirect.png'),
    });

    // Step 5: Assert other feature (Crew Search) is allowed
    const directCrew = await userPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('QueryCrew.aspx');
    expect(await userPage.title()).toContain('Crew Search');

    // Step 6: Control user of same role keeps full access
    const controlContext = await browser.newContext();
    const controlPage = await controlContext.newPage();
    await login(controlPage, MANNING_CONTROL_USER, MANNING_CONTROL_PASS);

    const ctrlCrewNav = await controlPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(ctrlCrewNav).toBeGreaterThan(0);
    const ctrlAppNav = await controlPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(ctrlAppNav).toBeGreaterThan(0);

    const controlCrew = await controlPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('QueryCrew.aspx');
    expect(await controlPage.title()).toContain('Crew Search');

    const controlApp = await controlPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('ApplicantPool.aspx');
    expect(await controlPage.title()).toContain('Applicant Pool');

    await controlPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc004-manning-control-access.png'),
    });

    // Step 7: Inspect denial audit entry
    const auditRes = await verifyAuditLog(adminPage, '/Applicant/ApplicantPool.aspx');
    expect(auditRes.found).toBe(true);
    console.log('[TC-CM-004 Audit Entry Verified]:', auditRes.logRows[0]);

    // Step 8: Restore settings and verify restored access
    await configureUserAccess(adminPage, MANNING_RESTRICTED_USER, true, true);

    const restoredContext = await browser.newContext();
    const restoredPage = await restoredContext.newPage();
    await login(restoredPage, MANNING_RESTRICTED_USER, MANNING_RESTRICTED_PASS);

    const rCrewNav = await restoredPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(rCrewNav).toBeGreaterThan(0);
    const rAppNav = await restoredPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(rAppNav).toBeGreaterThan(0);

    await restoredPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('QueryCrew.aspx');
    expect(await restoredPage.title()).toContain('Crew Search');

    await restoredPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('ApplicantPool.aspx');
    expect(await restoredPage.title()).toContain('Applicant Pool');

    await restoredPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc004-manning-restored-access.png'),
    });
    await restoredContext.close();

    await adminContext.tracing.stop({ path: path.join(TRACE_DIR, 'tc004-trace.zip') });
    await userContext.close();
    await controlContext.close();
    await adminContext.close();
  });

  // ==========================================================================
  // TC-CM-006: Documentation Officer with Crew Search disabled
  // ==========================================================================
  test('TC-CM-006: Documentation Officer with Crew Search disabled', async ({ browser }) => {
    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();
    await adminContext.tracing.start({ screenshots: true, snapshots: true });

    // Step 1 & 2: Configure qa2contact.doc.restricted -> CrewSearch = false, ApplicantPool = true
    await login(adminPage, SUPERADMIN_USER, SUPERADMIN_PASS);
    await configureUserAccess(adminPage, DOC_RESTRICTED_USER, false, true);

    await adminPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc006-doc-crewsearch-disabled-config.png'),
    });

    // Step 3: Sign in as restricted user
    const userContext = await browser.newContext();
    const userPage = await userContext.newPage();
    await login(userPage, DOC_RESTRICTED_USER, DOC_RESTRICTED_PASS);

    // Step 4: Assert Crew Search menu link is hidden and direct access denied
    const navCrewLinks = await userPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(navCrewLinks).toBe(0);

    const directCrew = await userPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('Home.aspx');
    expect(await userPage.title()).toContain('Dashboard');

    await userPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc006-doc-crewsearch-denied-redirect.png'),
    });

    // Step 5: Assert other feature (Applicant Pool) is allowed
    const directApp = await userPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('ApplicantPool.aspx');
    expect(await userPage.title()).toContain('Applicant Pool');

    // Step 6: Control user of same role keeps full access
    const controlContext = await browser.newContext();
    const controlPage = await controlContext.newPage();
    await login(controlPage, DOC_CONTROL_USER, DOC_CONTROL_PASS);

    const ctrlCrewNav = await controlPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(ctrlCrewNav).toBeGreaterThan(0);
    const ctrlAppNav = await controlPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(ctrlAppNav).toBeGreaterThan(0);

    const controlCrew = await controlPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('QueryCrew.aspx');
    expect(await controlPage.title()).toContain('Crew Search');

    const controlApp = await controlPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('ApplicantPool.aspx');
    expect(await controlPage.title()).toContain('Applicant Pool');

    await controlPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc006-doc-control-access.png'),
    });

    // Step 7: Inspect denial audit entry
    const auditRes = await verifyAuditLog(adminPage, '/Crew/QueryCrew.aspx');
    expect(auditRes.found).toBe(true);
    console.log('[TC-CM-006 Audit Entry Verified]:', auditRes.logRows[0]);

    // Step 8: Restore settings and verify restored access
    await configureUserAccess(adminPage, DOC_RESTRICTED_USER, true, true);

    const restoredContext = await browser.newContext();
    const restoredPage = await restoredContext.newPage();
    await login(restoredPage, DOC_RESTRICTED_USER, DOC_RESTRICTED_PASS);

    const rCrewNav = await restoredPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(rCrewNav).toBeGreaterThan(0);
    const rAppNav = await restoredPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(rAppNav).toBeGreaterThan(0);

    await restoredPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('QueryCrew.aspx');
    expect(await restoredPage.title()).toContain('Crew Search');

    await restoredPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('ApplicantPool.aspx');
    expect(await restoredPage.title()).toContain('Applicant Pool');

    await restoredPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc006-doc-restored-access.png'),
    });
    await restoredContext.close();

    await adminContext.tracing.stop({ path: path.join(TRACE_DIR, 'tc006-trace.zip') });
    await userContext.close();
    await controlContext.close();
    await adminContext.close();
  });

  // ==========================================================================
  // TC-CM-008: Documentation Officer with Applicant Pool disabled
  // ==========================================================================
  test('TC-CM-008: Documentation Officer with Applicant Pool disabled', async ({ browser }) => {
    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();
    await adminContext.tracing.start({ screenshots: true, snapshots: true });

    // Step 1 & 2: Configure qa2contact.doc.restricted -> CrewSearch = true, ApplicantPool = false
    await login(adminPage, SUPERADMIN_USER, SUPERADMIN_PASS);
    await configureUserAccess(adminPage, DOC_RESTRICTED_USER, true, false);

    await adminPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc008-doc-applicantpool-disabled-config.png'),
    });

    // Step 3: Sign in as restricted user
    const userContext = await browser.newContext();
    const userPage = await userContext.newPage();
    await login(userPage, DOC_RESTRICTED_USER, DOC_RESTRICTED_PASS);

    // Step 4: Assert Applicant Pool menu link is hidden and direct access denied
    const navAppLinks = await userPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(navAppLinks).toBe(0);

    const directApp = await userPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('Home.aspx');
    expect(await userPage.title()).toContain('Dashboard');

    await userPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc008-doc-applicantpool-denied-redirect.png'),
    });

    // Step 5: Assert other feature (Crew Search) is allowed
    const directCrew = await userPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('QueryCrew.aspx');
    expect(await userPage.title()).toContain('Crew Search');

    // Step 6: Control user of same role keeps full access
    const controlContext = await browser.newContext();
    const controlPage = await controlContext.newPage();
    await login(controlPage, DOC_CONTROL_USER, DOC_CONTROL_PASS);

    const ctrlCrewNav = await controlPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(ctrlCrewNav).toBeGreaterThan(0);
    const ctrlAppNav = await controlPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(ctrlAppNav).toBeGreaterThan(0);

    const controlCrew = await controlPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('QueryCrew.aspx');
    expect(await controlPage.title()).toContain('Crew Search');

    const controlApp = await controlPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('ApplicantPool.aspx');
    expect(await controlPage.title()).toContain('Applicant Pool');

    await controlPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc008-doc-control-access.png'),
    });

    // Step 7: Inspect denial audit entry
    const auditRes = await verifyAuditLog(adminPage, '/Applicant/ApplicantPool.aspx');
    expect(auditRes.found).toBe(true);
    console.log('[TC-CM-008 Audit Entry Verified]:', auditRes.logRows[0]);

    // Step 8: Restore settings and verify restored access
    await configureUserAccess(adminPage, DOC_RESTRICTED_USER, true, true);

    const restoredContext = await browser.newContext();
    const restoredPage = await restoredContext.newPage();
    await login(restoredPage, DOC_RESTRICTED_USER, DOC_RESTRICTED_PASS);

    const rCrewNav = await restoredPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(rCrewNav).toBeGreaterThan(0);
    const rAppNav = await restoredPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(rAppNav).toBeGreaterThan(0);

    await restoredPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('QueryCrew.aspx');
    expect(await restoredPage.title()).toContain('Crew Search');

    await restoredPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('ApplicantPool.aspx');
    expect(await restoredPage.title()).toContain('Applicant Pool');

    await restoredPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc008-doc-restored-access.png'),
    });
    await restoredContext.close();

    await adminContext.tracing.stop({ path: path.join(TRACE_DIR, 'tc008-trace.zip') });
    await userContext.close();
    await controlContext.close();
    await adminContext.close();
  });

  // ==========================================================================
  // TC-CM-010: Admin with Crew Search disabled
  // ==========================================================================
  test('TC-CM-010: Admin with Crew Search disabled', async ({ browser }) => {
    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();
    await adminContext.tracing.start({ screenshots: true, snapshots: true });

    // Step 1 & 2: Configure qa2contact.admin.restricted -> CrewSearch = false, ApplicantPool = true
    await login(adminPage, SUPERADMIN_USER, SUPERADMIN_PASS);
    await configureUserAccess(adminPage, ADMIN_RESTRICTED_USER, false, true);

    await adminPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc010-admin-crewsearch-disabled-config.png'),
    });

    // Step 3: Sign in as restricted user
    const userContext = await browser.newContext();
    const userPage = await userContext.newPage();
    await login(userPage, ADMIN_RESTRICTED_USER, ADMIN_RESTRICTED_PASS);

    // Step 4: Assert Crew Search menu link is hidden and direct access denied
    const navCrewLinks = await userPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(navCrewLinks).toBe(0);

    const directCrew = await userPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('Home.aspx');
    expect(await userPage.title()).toContain('Dashboard');

    await userPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc010-admin-crewsearch-denied-redirect.png'),
    });

    // Step 5: Assert other feature (Applicant Pool) is allowed
    const directApp = await userPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('ApplicantPool.aspx');
    expect(await userPage.title()).toContain('Applicant Pool');

    // Step 6: Control user of same role keeps full access
    const controlContext = await browser.newContext();
    const controlPage = await controlContext.newPage();
    await login(controlPage, ADMIN_CONTROL_USER, ADMIN_CONTROL_PASS);

    const ctrlCrewNav = await controlPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(ctrlCrewNav).toBeGreaterThan(0);
    const ctrlAppNav = await controlPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(ctrlAppNav).toBeGreaterThan(0);

    const controlCrew = await controlPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('QueryCrew.aspx');
    expect(await controlPage.title()).toContain('Crew Search');

    const controlApp = await controlPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('ApplicantPool.aspx');
    expect(await controlPage.title()).toContain('Applicant Pool');

    await controlPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc010-admin-control-access.png'),
    });

    // Step 7: Inspect denial audit entry
    const auditRes = await verifyAuditLog(adminPage, '/Crew/QueryCrew.aspx');
    expect(auditRes.found).toBe(true);
    console.log('[TC-CM-010 Audit Entry Verified]:', auditRes.logRows[0]);

    // Step 8: Restore settings and verify restored access
    await configureUserAccess(adminPage, ADMIN_RESTRICTED_USER, true, true);

    const restoredContext = await browser.newContext();
    const restoredPage = await restoredContext.newPage();
    await login(restoredPage, ADMIN_RESTRICTED_USER, ADMIN_RESTRICTED_PASS);

    const rCrewNav = await restoredPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(rCrewNav).toBeGreaterThan(0);
    const rAppNav = await restoredPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(rAppNav).toBeGreaterThan(0);

    await restoredPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('QueryCrew.aspx');
    expect(await restoredPage.title()).toContain('Crew Search');

    await restoredPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('ApplicantPool.aspx');
    expect(await restoredPage.title()).toContain('Applicant Pool');

    await restoredPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc010-admin-restored-access.png'),
    });
    await restoredContext.close();

    await adminContext.tracing.stop({ path: path.join(TRACE_DIR, 'tc010-trace.zip') });
    await userContext.close();
    await controlContext.close();
    await adminContext.close();
  });

  // ==========================================================================
  // TC-CM-013: Admin with Applicant Pool disabled
  // ==========================================================================
  test('TC-CM-013: Admin with Applicant Pool disabled', async ({ browser }) => {
    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();
    await adminContext.tracing.start({ screenshots: true, snapshots: true });

    // Step 1 & 2: Configure qa2contact.admin.restricted -> CrewSearch = true, ApplicantPool = false
    await login(adminPage, SUPERADMIN_USER, SUPERADMIN_PASS);
    await configureUserAccess(adminPage, ADMIN_RESTRICTED_USER, true, false);

    await adminPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc013-admin-applicantpool-disabled-config.png'),
    });

    // Step 3: Sign in as restricted user
    const userContext = await browser.newContext();
    const userPage = await userContext.newPage();
    await login(userPage, ADMIN_RESTRICTED_USER, ADMIN_RESTRICTED_PASS);

    // Step 4: Assert Applicant Pool menu link is hidden and direct access denied
    const navAppLinks = await userPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(navAppLinks).toBe(0);

    const directApp = await userPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('Home.aspx');
    expect(await userPage.title()).toContain('Dashboard');

    await userPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc013-admin-applicantpool-denied-redirect.png'),
    });

    // Step 5: Assert other feature (Crew Search) is allowed
    const directCrew = await userPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('QueryCrew.aspx');
    expect(await userPage.title()).toContain('Crew Search');

    // Step 6: Control user of same role keeps full access
    const controlContext = await browser.newContext();
    const controlPage = await controlContext.newPage();
    await login(controlPage, ADMIN_CONTROL_USER, ADMIN_CONTROL_PASS);

    const ctrlCrewNav = await controlPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(ctrlCrewNav).toBeGreaterThan(0);
    const ctrlAppNav = await controlPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(ctrlAppNav).toBeGreaterThan(0);

    const controlCrew = await controlPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('QueryCrew.aspx');
    expect(await controlPage.title()).toContain('Crew Search');

    const controlApp = await controlPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(controlPage.url()).toContain('ApplicantPool.aspx');
    expect(await controlPage.title()).toContain('Applicant Pool');

    await controlPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc013-admin-control-access.png'),
    });

    // Step 7: Inspect denial audit entry
    const auditRes = await verifyAuditLog(adminPage, '/Applicant/ApplicantPool.aspx');
    expect(auditRes.found).toBe(true);
    console.log('[TC-CM-013 Audit Entry Verified]:', auditRes.logRows[0]);

    // Step 8: Restore settings and verify restored access
    await configureUserAccess(adminPage, ADMIN_RESTRICTED_USER, true, true);

    const restoredContext = await browser.newContext();
    const restoredPage = await restoredContext.newPage();
    await login(restoredPage, ADMIN_RESTRICTED_USER, ADMIN_RESTRICTED_PASS);

    const rCrewNav = await restoredPage.locator('.topnav-dropdown-item[href*="QueryCrew"]').count();
    expect(rCrewNav).toBeGreaterThan(0);
    const rAppNav = await restoredPage.locator('.topnav-dropdown-item[href*="ApplicantPool"]').count();
    expect(rAppNav).toBeGreaterThan(0);

    await restoredPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('QueryCrew.aspx');
    expect(await restoredPage.title()).toContain('Crew Search');

    await restoredPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(restoredPage.url()).toContain('ApplicantPool.aspx');
    expect(await restoredPage.title()).toContain('Applicant Pool');

    await restoredPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc013-admin-restored-access.png'),
    });
    await restoredContext.close();

    await adminContext.tracing.stop({ path: path.join(TRACE_DIR, 'tc013-trace.zip') });
    await userContext.close();
    await controlContext.close();
    await adminContext.close();
  });

  // ==========================================================================
  // TC-CM-015: Super-Admin Crew Search Disable Setting (Bypass Rule Verification)
  // ==========================================================================
  test('TC-CM-015: Super-Admin Crew Search Bypass Rule Verification', async ({ browser }) => {
    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();
    await adminContext.tracing.start({ screenshots: true, snapshots: true });

    await login(adminPage, SUPERADMIN_USER, SUPERADMIN_PASS);
    await adminPage.goto('/Settings/UserAccounts.aspx', { waitUntil: 'domcontentloaded' });
    await adminPage.waitForTimeout(1000);

    await adminPage.fill('#ContentPlaceHolder1_txtSearch', SUPERADMIN_RESTRICTED_USER);
    await adminPage.click('#ContentPlaceHolder1_btnSearch');
    await adminPage.waitForTimeout(1500);

    const row = adminPage.locator(`table[id*="gvUsers"] tr:has-text("${SUPERADMIN_RESTRICTED_USER}")`).first();
    await expect(row).toBeVisible();
    await row.locator('a:has-text("Manage")').click();
    await pageWait(adminPage, 1500);

    // Verify UI prevents editing and shows "Always allowed" / Super-Admin Bypass
    const bypassAlert = adminPage.locator('text=Super-Admin Bypass Active');
    await expect(bypassAlert).toBeVisible();
    const alwaysAllowedText = adminPage.locator('text=Always allowed');
    await expect(alwaysAllowedText).toBeVisible();

    // Verify checkbox controls are omitted
    const crewCheckboxCount = await adminPage.locator('#ContentPlaceHolder1_chkAllowCrewSearch').count();
    expect(crewCheckboxCount).toBe(0);

    await adminPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc015-superadmin-bypass-ui.png'),
    });

    // Verify direct Crew Search access for Super-Admin
    const userContext = await browser.newContext();
    const userPage = await userContext.newPage();
    await login(userPage, SUPERADMIN_RESTRICTED_USER, SUPERADMIN_RESTRICTED_PASS);

    const directCrew = await userPage.goto('/Crew/QueryCrew.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('QueryCrew.aspx');
    expect(await userPage.title()).toContain('Crew Search');

    await userPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc015-superadmin-crewsearch-bypass-access.png'),
    });

    await adminContext.tracing.stop({ path: path.join(TRACE_DIR, 'tc015-trace.zip') });
    await userContext.close();
    await adminContext.close();
  });

  // ==========================================================================
  // TC-CM-017: Super-Admin Applicant Pool Disable Setting (Bypass Rule Verification)
  // ==========================================================================
  test('TC-CM-017: Super-Admin Applicant Pool Bypass Rule Verification', async ({ browser }) => {
    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();
    await adminContext.tracing.start({ screenshots: true, snapshots: true });

    await login(adminPage, SUPERADMIN_USER, SUPERADMIN_PASS);
    await adminPage.goto('/Settings/UserAccounts.aspx', { waitUntil: 'domcontentloaded' });
    await pageWait(adminPage, 1000);

    await adminPage.fill('#ContentPlaceHolder1_txtSearch', SUPERADMIN_RESTRICTED_USER);
    await adminPage.click('#ContentPlaceHolder1_btnSearch');
    await pageWait(adminPage, 1500);

    const row = adminPage.locator(`table[id*="gvUsers"] tr:has-text("${SUPERADMIN_RESTRICTED_USER}")`).first();
    await expect(row).toBeVisible();
    await row.locator('a:has-text("Manage")').click();
    await pageWait(adminPage, 1500);

    // Verify UI prevents editing and shows "Always allowed"
    const bypassAlert = adminPage.locator('text=Super-Admin Bypass Active');
    await expect(bypassAlert).toBeVisible();

    const appCheckboxCount = await adminPage.locator('#ContentPlaceHolder1_chkAllowApplicantPool').count();
    expect(appCheckboxCount).toBe(0);

    await adminPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc017-superadmin-bypass-ui.png'),
    });

    // Verify direct Applicant Pool access for Super-Admin
    const userContext = await browser.newContext();
    const userPage = await userContext.newPage();
    await login(userPage, SUPERADMIN_RESTRICTED_USER, SUPERADMIN_RESTRICTED_PASS);

    const directApp = await userPage.goto('/Applicant/ApplicantPool.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('ApplicantPool.aspx');
    expect(await userPage.title()).toContain('Applicant Pool');

    await userPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'tc017-superadmin-applicantpool-bypass-access.png'),
    });

    await adminContext.tracing.stop({ path: path.join(TRACE_DIR, 'tc017-trace.zip') });
    await userContext.close();
    await adminContext.close();
  });

  // ==========================================================================
  // Unauthorized Account Management Protection Check
  // ==========================================================================
  test('Security Rule: Unauthorized User Cannot Access or Save User Account Overrides', async ({ browser }) => {
    const userContext = await browser.newContext();
    const userPage = await userContext.newPage();
    await userContext.tracing.start({ screenshots: true, snapshots: true });

    // Login as standard Manning Staff
    await login(userPage, MANNING_CONTROL_USER, MANNING_CONTROL_PASS);

    // 1. Assert navigation link is completely hidden
    const navLinks = await userPage.locator('a[href*="UserAccounts.aspx"]').count();
    expect(navLinks).toBe(0);

    // 2. Assert direct URL access is denied and redirected to Dashboard
    const res = await userPage.goto('/Settings/UserAccounts.aspx', { waitUntil: 'domcontentloaded' });
    expect(userPage.url()).toContain('Home.aspx');
    expect(await userPage.title()).toContain('Dashboard');

    await userPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'security-unauthorized-useraccounts-redirect.png'),
    });

    // 3. SuperAdmin verifies the Security denial log
    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();
    await login(adminPage, SUPERADMIN_USER, SUPERADMIN_PASS);

    const auditRes = await verifyAuditLog(adminPage, '/Settings/UserAccounts.aspx');
    expect(auditRes.found).toBe(true);
    console.log('[Security Audit Verified]:', auditRes.logRows[0]);

    await adminPage.screenshot({
      path: path.join(SCREENSHOT_DIR, 'security-denial-audit-log.png'),
      fullPage: true,
    });

    await userContext.tracing.stop({ path: path.join(TRACE_DIR, 'security-unauthorized-trace.zip') });
    await adminContext.close();
    await userContext.close();
  });

});

function pageWait(page, ms) {
  return page.waitForTimeout(ms);
}
