import { test, expect, Page } from '../../fixtures/auth.fixture';
import path from 'path';
import fs from 'fs';

// ============================================================================
// Synthetic Test Artifact Paths
// ============================================================================
const FIXTURES_DIR = path.resolve(__dirname, '../../test-data/ai-fixtures');
const VALID_LICENSE_PDF = path.join(FIXTURES_DIR, 'valid_license.pdf');
const VALID_CERT_JPG = path.join(FIXTURES_DIR, 'valid_cert.jpg');
const VALID_CERT_JPEG = path.join(FIXTURES_DIR, 'valid_cert.jpeg');
const VALID_ID_PNG = path.join(FIXTURES_DIR, 'valid_id.png');
const INVALID_TEXT_TXT = path.join(FIXTURES_DIR, 'invalid_text.txt');
const INVALID_SCRIPT_EXE = path.join(FIXTURES_DIR, 'invalid_script.exe');
const CORRUPT_PDF = path.join(FIXTURES_DIR, 'corrupt.pdf');
const CORRUPT_JPG = path.join(FIXTURES_DIR, 'corrupt.jpg');
const OVERSIZED_DOC_PDF = path.join(FIXTURES_DIR, 'oversized_doc.pdf');
const OVERPAGE_DOC_PDF = path.join(FIXTURES_DIR, 'overpage_doc.pdf');
const MANIFEST_RESUME_PDF = path.join(FIXTURES_DIR, 'synthetic_manifest_resume.pdf');
const SYNTHETIC_PASSPORT_PDF = path.join(FIXTURES_DIR, 'synthetic_passport.pdf');

const MULTI_11_FILES = Array.from({ length: 11 }, (_, i) =>
  path.join(FIXTURES_DIR, `multi_${String(i + 1).padStart(2, '0')}.pdf`)
);

const BATCH_OVER_25MB_FILES = Array.from({ length: 6 }, (_, i) =>
  path.join(FIXTURES_DIR, `batch_size_${i + 1}.pdf`)
);

// Prefix for isolated synthetic data
const DATA_PREFIX = 'QA-C2-EVIDENCE-20261004';

// ============================================================================
// Helper Utilities
// ============================================================================
function getTomorrowDateString(): string {
  const d = new Date();
  d.setDate(d.getDate() + 1);
  return d.toISOString().split('T')[0];
}

async function generateApplicantLink(page: Page, applicantName: string, applicantEmail: string): Promise<string> {
  await page.goto('/Applicant/ApplicantPool.aspx');
  await page.waitForLoadState('networkidle').catch(() => {});

  const genBtn = page.locator('[id$="btnGenerateLink"]');
  await Promise.all([
    page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST').catch(() => {}),
    genBtn.click(),
  ]);
  await page.waitForLoadState('networkidle').catch(() => {});

  await page.locator('[id$="txtLinkFullname"]').fill(applicantName);
  await page.locator('[id$="txtLinkEmail"]').fill(applicantEmail);
  await page.locator('[id$="txtLinkValidity"]').fill(getTomorrowDateString());

  await page.locator('[id$="btnCreateLink"]').click();
  await page.waitForLoadState('networkidle').catch(() => {});

  const linkInput = page.locator('[id$="txtGeneratedLink"]');
  await expect(linkInput).toBeVisible({ timeout: 10000 });
  return await linkInput.inputValue();
}

async function cleanupApplicantLink(page: Page, applicantName: string) {
  try {
    await page.goto('/Applicant/ApplicantPool.aspx');
    await page.waitForLoadState('networkidle').catch(() => {});

    const isAlreadyVisible = await page.locator('[id$="panelManageLinks"]').isVisible().catch(() => false);
    if (!isAlreadyVisible) {
      const manageBtn = page.locator('[id$="btnManageLinks"]');
      await Promise.all([
        page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST').catch(() => {}),
        manageBtn.click(),
      ]);
      await page.waitForLoadState('networkidle').catch(() => {});
    }

    const row = page.locator(`tr:has-text("${applicantName}")`).first();
    if (await row.count() > 0) {
      const expireBtn = row.locator('input[value*="Expire"], button:has-text("Expire"), a:has-text("Expire")').first();
      if (await expireBtn.count() > 0) {
        await expireBtn.click();
        await page.waitForLoadState('networkidle').catch(() => {});
      }
    }
  } catch (e) {
    // Teardown safety
  }
}

async function waitForExtractionTerminalState(appPage: Page, timeoutMs = 60000): Promise<'COMPLETED' | 'ERROR'> {
  const result = await Promise.race([
    appPage.locator('#aiCompletionBox').waitFor({ state: 'visible', timeout: timeoutMs }).then(() => 'COMPLETED' as const),
    appPage.locator('#aiErrorBox').waitFor({ state: 'visible', timeout: timeoutMs }).then(() => 'ERROR' as const),
  ]);
  return result;
}

// ============================================================================
// Test Suite: Evidence Review
// ============================================================================
test.describe('UMMI Cycle 2 — Evidence Review Test Suite', () => {

  // --------------------------------------------------------------------------
  // TC-CM-207: Complete Upload Validation
  // --------------------------------------------------------------------------
  test('TC-CM-207: Complete Upload Validation (All 13 Boundaries)', async ({ loginAsRole, page, browser }) => {
    const testName = `${DATA_PREFIX}-TC207-UploadValidation`;
    const testEmail = `evidence-tc207-${Date.now()}@example.com`;
    let linkUrl = '';

    await test.step('Prerequisite: Generate applicant link and initialize self-encoding session', async () => {
      await loginAsRole('MANNING');
      linkUrl = await generateApplicantLink(page, testName, testEmail);
      expect(linkUrl).toBeTruthy();
    });

    const appCtx = await browser.newContext();
    const appPage = await appCtx.newPage();
    await appPage.goto(linkUrl);
    await appPage.waitForLoadState('networkidle');

    // Accept AI consent
    const chkConsent = appPage.locator('#chkAiConsent');
    await expect(chkConsent).toBeVisible();
    await chkConsent.check();

    const fileInput = appPage.locator('#aiFileInput');
    const errorBox = appPage.locator('#aiErrorBox');
    const errorMsg = appPage.locator('#aiErrorMessage');
    const retryBtn = appPage.locator('#btnAiRetry');

    // 1. Supported PDF file
    await test.step('Scenario 1: Supported PDF file (.pdf)', async () => {
      await fileInput.setInputFiles([VALID_LICENSE_PDF]);
      await appPage.waitForTimeout(1000);
      await expect(errorBox).not.toBeVisible();
      const progressOrDropzone = await appPage.locator('#aiProgressContainer, #aiDropzone').count();
      expect(progressOrDropzone).toBeGreaterThan(0);
      await appPage.evaluate(() => (window as any).ApplicantAiAssist.resetUploadState());
      await appPage.waitForTimeout(500);
    });

    // 2. Supported JPG file
    await test.step('Scenario 2: Supported JPG file (.jpg)', async () => {
      await fileInput.setInputFiles([VALID_CERT_JPG]);
      await appPage.waitForTimeout(1000);
      await expect(errorBox).not.toBeVisible();
      await appPage.evaluate(() => (window as any).ApplicantAiAssist.resetUploadState());
      await appPage.waitForTimeout(500);
    });

    // 3. Supported JPEG file
    await test.step('Scenario 3: Supported JPEG file (.jpeg)', async () => {
      await fileInput.setInputFiles([VALID_CERT_JPEG]);
      await appPage.waitForTimeout(1000);
      await expect(errorBox).not.toBeVisible();
      await appPage.evaluate(() => (window as any).ApplicantAiAssist.resetUploadState());
      await appPage.waitForTimeout(500);
    });

    // 4. Supported PNG file
    await test.step('Scenario 4: Supported PNG file (.png)', async () => {
      await fileInput.setInputFiles([VALID_ID_PNG]);
      await appPage.waitForTimeout(1000);
      await expect(errorBox).not.toBeVisible();
      await appPage.evaluate(() => (window as any).ApplicantAiAssist.resetUploadState());
      await appPage.waitForTimeout(500);
    });

    // 5. Unsupported .txt file
    await test.step('Scenario 5: Unsupported .txt file', async () => {
      await fileInput.setInputFiles([INVALID_TEXT_TXT]);
      await expect(errorBox).toBeVisible({ timeout: 5000 });
      const msg = await errorMsg.innerText();
      expect(msg).toMatch(/unsupported file format|Allowed formats/i);
      await retryBtn.click();
      await expect(errorBox).not.toBeVisible();
    });

    // 6. Unsupported .exe file
    await test.step('Scenario 6: Unsupported .exe file', async () => {
      await fileInput.setInputFiles([INVALID_SCRIPT_EXE]);
      await expect(errorBox).toBeVisible({ timeout: 5000 });
      const msg = await errorMsg.innerText();
      expect(msg).toMatch(/unsupported file format|Allowed formats/i);
      await retryBtn.click();
      await expect(errorBox).not.toBeVisible();
    });

    // 7. Corrupt or unreadable PDF
    await test.step('Scenario 7: Corrupt or unreadable PDF (invalid magic bytes)', async () => {
      await fileInput.setInputFiles([CORRUPT_PDF]);
      // Client allows extension; server magic-byte check rejects with 400
      await expect(errorBox).toBeVisible({ timeout: 15000 });
      const msg = await errorMsg.innerText();
      expect(msg).toMatch(/not match a valid PDF document signature|validation failed|Upload failed with status 400/i);
      await retryBtn.click();
      await expect(errorBox).not.toBeVisible();
    });

    // 8. Corrupt or unreadable image
    await test.step('Scenario 8: Corrupt or unreadable image (invalid magic bytes)', async () => {
      await fileInput.setInputFiles([CORRUPT_JPG]);
      await expect(errorBox).toBeVisible({ timeout: 15000 });
      const msg = await errorMsg.innerText();
      expect(msg).toMatch(/not match a valid JPEG image signature|validation failed|Upload failed with status 400/i);
      await retryBtn.click();
      await expect(errorBox).not.toBeVisible();
    });

    // 9. Individual file larger than 5 MB
    await test.step('Scenario 9: Individual file larger than 5 MB', async () => {
      await fileInput.setInputFiles([OVERSIZED_DOC_PDF]);
      await expect(errorBox).toBeVisible({ timeout: 5000 });
      const msg = await errorMsg.innerText();
      expect(msg).toMatch(/exceeds the 5 MB limit/i);
      await retryBtn.click();
      await expect(errorBox).not.toBeVisible();
    });

    // 10. More than 10 files in one selection or session
    await test.step('Scenario 10: More than 10 files in one selection', async () => {
      await fileInput.setInputFiles(MULTI_11_FILES);
      await expect(errorBox).toBeVisible({ timeout: 5000 });
      const msg = await errorMsg.innerText();
      expect(msg).toMatch(/maximum of 10 documents per session/i);
      await retryBtn.click();
      await expect(errorBox).not.toBeVisible();
    });

    // 11. Combined file size greater than 25 MB
    await test.step('Scenario 11: Combined file size greater than 25 MB', async () => {
      await fileInput.setInputFiles(BATCH_OVER_25MB_FILES);
      await expect(errorBox).toBeVisible({ timeout: 5000 });
      const msg = await errorMsg.innerText();
      expect(msg).toMatch(/exceeds the 25 MB limit/i);
      await retryBtn.click();
      await expect(errorBox).not.toBeVisible();
    });

    // 12. PDF containing more than 10 pages
    await test.step('Scenario 12: PDF containing more than 10 pages', async () => {
      await fileInput.setInputFiles([OVERPAGE_DOC_PDF]);
      // Extraction pipeline evaluates page count
      await expect(errorBox).toBeVisible({ timeout: 45000 });
      const msg = await errorMsg.innerText();
      expect(msg).toMatch(/exceeds the maximum allowable page count of 10 pages|11 pages|failed/i);
      await retryBtn.click();
      await expect(errorBox).not.toBeVisible();
    });

    // 13. Valid file immediately after rejected files
    await test.step('Scenario 13: Valid file immediately after rejected files', async () => {
      await fileInput.setInputFiles([VALID_LICENSE_PDF]);
      await appPage.waitForTimeout(2000);
      await expect(errorBox).not.toBeVisible();
      // Interface is usable; progress container or dropzone active
      const dropzoneOrProg = await appPage.locator('#aiProgressContainer, #aiDropzone').count();
      expect(dropzoneOrProg).toBeGreaterThan(0);
    });

    await appCtx.close();
    await cleanupApplicantLink(page, testName);
  });

  // --------------------------------------------------------------------------
  // TC-CM-212: Explicit Field-Suggestion Rejection
  // --------------------------------------------------------------------------
  test('TC-CM-212: Explicit Field-Suggestion Rejection (Accept, Edit, Reject, Manual Completion)', async ({ loginAsRole, page, browser }) => {
    const testName = `${DATA_PREFIX}-TC212-FieldRejection`;
    const testEmail = `evidence-tc212-${Date.now()}@example.com`;
    let linkUrl = '';

    await test.step('Prerequisite: Generate applicant link and upload synthetic manifest resume', async () => {
      await loginAsRole('MANNING');
      linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();
      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const state = await waitForExtractionTerminalState(appPage);
      expect(state).toBe('COMPLETED');

      // 1. Produce a normal scalar field suggestion and record destination field
      await test.step('Action 1: Record original destination field and inspect scalar suggestion controls', async () => {
        const middleNameInput = appPage.locator('[id$="txtMiddleName"]');
        const origMiddleNameVal = await middleNameInput.inputValue();
        expect(origMiddleNameVal).toBe('');

        const lastNameInput = appPage.locator('[id$="txtLastName"]');
        const origLastNameVal = await lastNameInput.inputValue();

        // Inspect ordinary scalar field suggestion slot for Middle Name
        const middleSlot = appPage.locator('#aiSuggestion_MiddleName');
        await expect(middleSlot).toBeVisible({ timeout: 5000 });
        const middleHtml = await middleSlot.innerHTML();
        const middleButtons = await middleSlot.locator('button').allInnerTexts();

        // Inspect ordinary scalar field suggestion slot for Last Name
        const lastSlot = appPage.locator('#aiSuggestion_LastName');
        await expect(lastSlot).toBeVisible({ timeout: 5000 });
        const lastHtml = await lastSlot.innerHTML();
        const lastButtons = await lastSlot.locator('button').allInnerTexts();

        console.log('TC-CM-212 Rendered DOM for #aiSuggestion_MiddleName:', middleHtml);
        console.log('TC-CM-212 Available controls on #aiSuggestion_MiddleName:', middleButtons);
        console.log('TC-CM-212 Rendered DOM for #aiSuggestion_LastName:', lastHtml);
        console.log('TC-CM-212 Available controls on #aiSuggestion_LastName:', lastButtons);

        // Check for actual Reject / Discard / Ignore / Dismiss control on scalar suggestion
        const rejectMiddleCtrl = middleSlot.locator('button:has-text("Reject"), button:has-text("Discard"), button:has-text("Ignore"), button:has-text("Dismiss"), a:has-text("Reject"), .btn-reject, .btn-discard, .btn-ignore');
        const rejectLastCtrl = lastSlot.locator('button:has-text("Reject"), button:has-text("Discard"), button:has-text("Ignore"), button:has-text("Dismiss"), a:has-text("Reject"), .btn-reject, .btn-discard, .btn-ignore');

        const hasMiddleReject = (await rejectMiddleCtrl.count()) > 0;
        const hasLastReject = (await rejectLastCtrl.count()) > 0;

        console.log(`TC-CM-212 Rejection Control Found on MiddleName: ${hasMiddleReject}, LastName: ${hasLastReject}`);

        // Per user instructions: If ordinary field suggestions have no rejection control,
        // do not mark Passed. Record as Failed / implementation gap against requirement to accept, edit, and reject suggestions.
        expect(hasMiddleReject || hasLastReject,
          'IMPLEMENTATION DEFECT: Ordinary scalar field suggestions only render "Apply" or "Replace" controls. ' +
          'No Reject, Discard, Ignore, or Dismiss control is provided in the DOM for scalar field suggestions. ' +
          'Leaving suggestions unapplied cannot substitute as evidence of rejection.'
        ).toBe(true);
      });

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-221: Protected Applicant Document Access
  // --------------------------------------------------------------------------
  test('TC-CM-221: Protected Applicant Document Access (Multi-Role Permission Matrix)', async ({ loginAsRole, page, browser, request }) => {
    const testName = `${DATA_PREFIX}-TC221-ApplicantDoc`;
    const testEmail = `evidence-tc221-${Date.now()}@example.com`;
    let linkUrl = '';
    let protectedDocUrl = '';
    let relativeDocUrl = '';

    await test.step('Step 1: Controlled applicant submission with genuine document retention', async () => {
      await loginAsRole('MANNING');
      linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();
      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      // Upload harmless uniquely identifiable synthetic PDF (1524 bytes)
      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([SYNTHETIC_PASSPORT_PDF]);

      const state = await waitForExtractionTerminalState(appPage);
      expect(state).toBe('COMPLETED');

      // Step 1: Fill required personal details
      const applyBtn = appPage.locator('#aiSuggestion_LastName .btn-apply-suggestion').first();
      if (await applyBtn.isVisible({ timeout: 1000 }).catch(() => false)) {
        await applyBtn.click().catch(() => {});
      }
      await appPage.locator('[id$="txtLastName"]').fill('Dela Cruz');
      await appPage.locator('[id$="txtFirstName"]').fill('Roberto');
      await appPage.locator('[id$="txtDOB"]').fill('1985-04-12');
      const rankDdl = appPage.locator('[id$="drpdwnRank"]');
      if (await rankDdl.isVisible()) {
        await rankDdl.selectOption({ index: 1 }).catch(() => {});
      }

      // Navigate to Step 2 (Repeating document review panel)
      const step2Btn = appPage.locator('.stepper-step:has-text("2"), button:has-text("Next")').first();
      await step2Btn.click();
      await appPage.waitForTimeout(1000);

      // Verify repeating document card on Step 2
      const docCard = appPage.locator('.ai-record-card[data-kind="doc"]').first();
      await expect(docCard).toBeVisible({ timeout: 10000 });
      expect(await docCard.locator('.ai-record-title').innerText()).toContain('Passport');
      expect(await docCard.locator('.ai-record-status-badge').innerText()).toBe('Pending');

      // Explicitly Accept repeating document card ("Keep for now")
      const keepBtn = docCard.locator('.btn-ai-keep');
      await expect(keepBtn).toBeVisible();
      await keepBtn.click();
      await appPage.waitForTimeout(500);

      // Confirm visibly updated to accepted state
      const keptBadge = docCard.locator('.ai-record-status-badge');
      expect(await keptBadge.innerText()).toBe('Kept for now');

      // Fill Contact Number
      const contactInput = appPage.locator('[id$="txtContact"]');
      if (await contactInput.isVisible()) {
        await contactInput.fill('0917-555-0199');
      }

      // Navigate to Step 3: Review & Submit
      const step3Btn = appPage.locator('.stepper-step:has-text("3"), button:has-text("Next")').first();
      await step3Btn.click();
      await appPage.waitForTimeout(1000);

      // Confirm accepted document decision is serialized
      const payloadValue = await appPage.evaluate(() => {
        const el = document.querySelector('[id$="hfAiRepeatingDecisions"]') as HTMLInputElement;
        return el ? el.value : '';
      });
      console.log('TC-CM-221 hfAiRepeatingDecisions serialized payload:', payloadValue);

      // Submit application
      const submitBtn = appPage.locator('[id$="btnSubmit"]');
      await expect(submitBtn).toBeVisible();
      await submitBtn.click();
      await appPage.waitForLoadState('networkidle').catch(() => {});
      await appPage.waitForTimeout(3000);

      const submitSuccess = await appPage.locator('.alert-success, :has-text("submitted successfully")').count();
      expect(submitSuccess).toBeGreaterThan(0);

      await appCtx.close();
    });

    await test.step('Step 2: Obtain actual protected document handler URL from application', async () => {
      await loginAsRole('MANNING');
      await page.goto('/Applicant/ApplicantPool.aspx');
      await page.waitForLoadState('networkidle');

      await page.locator('[id$="txtLastName"]').fill('Dela Cruz');
      await page.locator('[id$="txtFirstName"]').fill('Roberto');
      await page.locator('[id$="btnSearch"]').click();
      await page.waitForLoadState('networkidle');

      const profileLinks = await page.locator('table a[href*="ProfileViewer.aspx"]').all();
      expect(profileLinks.length).toBeGreaterThan(0);

      const profileHref = await profileLinks[0].getAttribute('href');
      expect(profileHref).toBeTruthy();
      const resolvedProfileUrl = profileHref!.startsWith('~') ? profileHref!.replace('~', '') : profileHref!;
      await page.goto(resolvedProfileUrl);
      await page.waitForLoadState('networkidle');

      // Locate actual scan link generated by application in ProfileViewer
      const docScans = await page.locator('a[onclick*="CrewDocumentHandler.ashx"]').all();
      expect(docScans.length).toBeGreaterThan(0);

      const onclickAttr = await docScans[0].getAttribute('onclick') || '';
      const match = onclickAttr.match(/showImagePopup\('([^']+)'\)/);
      expect(match).toBeTruthy();
      relativeDocUrl = match![1];

      const baseUrl = page.url().split('/Crew/')[0];
      protectedDocUrl = baseUrl + (relativeDocUrl.startsWith('/') ? relativeDocUrl : '/' + relativeDocUrl);
      console.log('TC-CM-221 Application-Generated Protected Handler URL:', protectedDocUrl);
      expect(protectedDocUrl).toMatch(/CrewDocumentHandler\.ashx\?id=\d+/);
    });

    // Identity 1: Authorized Manning Staff
    await test.step('Identity 1: Authorized Manning Staff access', async () => {
      await loginAsRole('MANNING');
      const res = await page.request.get(protectedDocUrl);
      const status = res.status();
      const contentType = res.headers()['content-type'] || '';
      const nosniff = res.headers()['x-content-type-options'] || '';
      const body = await res.body();
      const hasPdfBytes = body.slice(0, 5).toString().includes('%PDF');

      console.log(`Identity 1 (Manning Staff): Status ${status}, Type ${contentType}, Nosniff ${nosniff}, Bytes ${body.length}, Valid PDF ${hasPdfBytes}`);
      expect(status).toBe(200);
      expect(contentType).toContain('application/pdf');
      expect(nosniff.toLowerCase()).toBe('nosniff');
      expect(hasPdfBytes).toBe(true);
      expect(body.length).toBe(1524);
    });

    // Identity 2: Authorized Documentation Officer
    await test.step('Identity 2: Authorized Documentation Officer access', async () => {
      await loginAsRole('DOCUMENTATION');
      const res = await page.request.get(protectedDocUrl);
      const status = res.status();
      const contentType = res.headers()['content-type'] || '';
      const body = await res.body();
      const hasPdfBytes = body.slice(0, 5).toString().includes('%PDF');

      console.log(`Identity 2 (Documentation): Status ${status}, Type ${contentType}, Bytes ${body.length}, Valid PDF ${hasPdfBytes}`);
      expect(status).toBe(200);
      expect(contentType).toContain('application/pdf');
      expect(hasPdfBytes).toBe(true);
      expect(body.length).toBe(1524);
    });

    // Identity 3: Restricted internal staff (viewcrewcontactdetails=0 denied sensitive Personal doc)
    await test.step('Identity 3: Restricted internal staff access (denied sensitive Personal document)', async () => {
      await loginAsRole('MANNING_RESTRICTED');
      const res = await page.request.get(protectedDocUrl);
      const status = res.status();
      const body = await res.body();
      const hasPdfBytes = body.slice(0, 5).toString().includes('%PDF');

      console.log(`Identity 3 (Restricted Staff): Status ${status}, PDF Bytes: ${hasPdfBytes}`);
      expect(status).toBe(403);
      expect(hasPdfBytes).toBe(false);
    });

    // Identity 4: Applicant
    await test.step('Identity 4: Applicant role access', async () => {
      await loginAsRole('APPLICANT');
      const res = await page.request.get(protectedDocUrl);
      const status = res.status();
      const body = await res.body();
      const hasPdfBytes = body.slice(0, 5).toString().includes('%PDF');

      console.log(`Identity 4 (Applicant): Status ${status}, PDF Bytes: ${hasPdfBytes}`);
      expect(status).toBe(403);
      expect(hasPdfBytes).toBe(false);
    });

    // Identity 5: Out-of-scope Principal
    await test.step('Identity 5: Principal access (vessel scoping enforced)', async () => {
      await loginAsRole('PRINCIPAL');
      const res = await page.request.get(protectedDocUrl);
      const status = res.status();
      const body = await res.body();
      const hasPdfBytes = body.slice(0, 5).toString().includes('%PDF');

      console.log(`Identity 5 (Principal): Status ${status}, PDF Bytes: ${hasPdfBytes}`);
      expect(status).toBe(403);
      expect(hasPdfBytes).toBe(false);
    });

    // Identity 6: Out-of-scope Vessel Owner
    await test.step('Identity 6: Vessel Owner access (vessel scoping enforced)', async () => {
      await loginAsRole('VESSEL_OWNER');
      const res = await page.request.get(protectedDocUrl);
      const status = res.status();
      const body = await res.body();
      const hasPdfBytes = body.slice(0, 5).toString().includes('%PDF');

      console.log(`Identity 6 (Vessel Owner): Status ${status}, PDF Bytes: ${hasPdfBytes}`);
      expect(status).toBe(403);
      expect(hasPdfBytes).toBe(false);
    });

    // Identity 7: Anonymous user
    await test.step('Identity 7: Anonymous unauthenticated access', async () => {
      const anonRes = await request.get(protectedDocUrl);
      const status = anonRes.status();
      const body = await anonRes.body();
      const hasPdfBytes = body.slice(0, 5).toString().includes('%PDF');

      console.log(`Identity 7 (Anonymous): Status ${status}, PDF Bytes: ${hasPdfBytes}`);
      expect(status).toBe(403);
      expect(hasPdfBytes).toBe(false);
    });

    // Direct Static Directory and File Access Check
    await test.step('Static Storage Security: Direct path access blocked', async () => {
      const staticDirRes = await request.get('/Uploads/documents/', { maxRedirects: 0 });
      console.log(`Static Directory Access (/Uploads/documents/): Status ${staticDirRes.status()}`);
      expect([302, 403, 404]).toContain(staticDirRes.status());
      if (staticDirRes.status() === 302) {
        expect(staticDirRes.headers()['location']).toMatch(/login\.aspx/i);
      }
    });

    // Cleanup
    await loginAsRole('MANNING');
    await cleanupApplicantLink(page, testName);
  });

});
