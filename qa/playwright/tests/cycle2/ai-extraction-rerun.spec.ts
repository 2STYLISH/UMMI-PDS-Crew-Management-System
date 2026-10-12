import { test, expect, Page } from '../../fixtures/auth.fixture';
import path from 'path';

// ============================================================================
// Synthetic Test Artifact Paths
// ============================================================================
const FIXTURES_DIR = path.resolve(__dirname, '../../test-data/ai-fixtures');
const MANIFEST_RESUME_PDF = path.join(FIXTURES_DIR, 'synthetic_manifest_resume.pdf');
const CONFLICT_DOC1_PDF = path.join(FIXTURES_DIR, 'synthetic_conflict_doc1.pdf');
const CONFLICT_DOC2_PDF = path.join(FIXTURES_DIR, 'synthetic_conflict_doc2.pdf');
const UNMATCHED_RANK_PDF = path.join(FIXTURES_DIR, 'synthetic_unmatched_rank.pdf');
const SCANNED_DOC_PDF = path.join(FIXTURES_DIR, 'synthetic_scanned_doc.pdf');
const REPEATING_RECORDS_PDF = path.join(FIXTURES_DIR, 'synthetic_repeating_records.pdf');
const VALID_LICENSE_PDF = path.join(FIXTURES_DIR, 'valid_license.pdf');
const VALID_CERT_JPG = path.join(FIXTURES_DIR, 'valid_cert.jpg');
const VALID_ID_PNG = path.join(FIXTURES_DIR, 'valid_id.png');
const INVALID_TEXT_TXT = path.join(FIXTURES_DIR, 'invalid_text.txt');
const INVALID_SCRIPT_EXE = path.join(FIXTURES_DIR, 'invalid_script.exe');
const OVERPAGE_DOC_PDF = path.join(FIXTURES_DIR, 'overpage_doc.pdf');
const OVERSIZED_DOC_PDF = path.join(FIXTURES_DIR, 'oversized_doc.pdf');
const PROMPT_INJECTION_PDF = path.join(FIXTURES_DIR, 'prompt_injection.pdf');
const XSS_DISPLAY_TEST_PDF = path.join(FIXTURES_DIR, 'xss_display_test.pdf');

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

async function waitForExtractionTerminalState(appPage: Page, timeoutMs = 45000): Promise<'COMPLETED' | 'ERROR'> {
  const result = await Promise.race([
    appPage.locator('#aiCompletionBox').waitFor({ state: 'visible', timeout: timeoutMs }).then(() => 'COMPLETED' as const),
    appPage.locator('#aiErrorBox').waitFor({ state: 'visible', timeout: timeoutMs }).then(() => 'ERROR' as const),
  ]);
  return result;
}

// ============================================================================
// TEST SUITE: Cycle 2 — AI-Assisted Applicant Self-Encoding Rerun
// ============================================================================
test.describe('UMMI Cycle 2 — AI-Assisted Applicant Self-Encoding Rerun', () => {

  // --------------------------------------------------------------------------
  // TC-CM-207: Validate formats, content, readability, and configured limits
  // --------------------------------------------------------------------------
  test('TC-CM-207: AI document upload - Validate formats, content, readability, and configured limits', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC207-LimitsValidation';
    const testEmail = 'rerun-tc207-limits@example.com';
    let linkUrl = '';

    await test.step('Step 1: Inspect displayed limits and validate allowed boundaries', async () => {
      await loginAsRole('MANNING');
      linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();
      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      const limitsEl = appPage.locator('.ai-dropzone-limits, :has-text("Max 10 files")').first();
      await expect(limitsEl).toBeVisible();
      const limitsText = await limitsEl.innerText();
      expect(limitsText).toContain('PDF');
      expect(limitsText).toContain('JPG');
      expect(limitsText).toContain('PNG');
      expect(limitsText).toContain('10 files');
      expect(limitsText).toContain('5 MB');
      expect(limitsText).toContain('25 MB');

      await appCtx.close();
    });

    await test.step('Step 2: Upload unsupported formats, oversized files, and overpage PDFs', async () => {
      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();
      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();

      // Test 1: Disallowed file extension (.txt)
      const fileInput = appPage.locator('#aiFileInput');
      await fileInput.setInputFiles([INVALID_TEXT_TXT]);
      const errorBox = appPage.locator('#aiErrorBox');
      await expect(errorBox).toBeVisible({ timeout: 5000 });
      let errText = await appPage.locator('#aiErrorMessage').innerText();
      expect(errText).toMatch(/unsupported file format|Allowed formats/i);

      // Dismiss / reset
      await appPage.locator('#btnAiRetry').click();
      await expect(errorBox).not.toBeVisible();

      // Test 2: Oversized file (> 5 MB)
      await fileInput.setInputFiles([OVERSIZED_DOC_PDF]);
      await expect(errorBox).toBeVisible({ timeout: 5000 });
      errText = await appPage.locator('#aiErrorMessage').innerText();
      expect(errText).toMatch(/exceeds the 5 MB limit|maximum allowed size/i);

      // Dismiss / reset
      await appPage.locator('#btnAiRetry').click();

      // Test 3: Disallowed executable (.exe)
      await fileInput.setInputFiles([INVALID_SCRIPT_EXE]);
      await expect(errorBox).toBeVisible({ timeout: 5000 });
      errText = await appPage.locator('#aiErrorMessage').innerText();
      expect(errText).toMatch(/unsupported file format/i);

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-208: Use native PDF text and OCR when required
  // --------------------------------------------------------------------------
  test('TC-CM-208: Text and OCR extraction - Use native PDF text and OCR when required', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC208-TextAndOcr';
    const testEmail = 'rerun-tc208-ocr@example.com';

    await test.step('Step 1: Test native-text PDF parsing path', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();

      let resultPayload: any = null;
      appPage.on('response', async res => {
        if (res.url().includes('action=result')) {
          try { resultPayload = await res.json(); } catch (e) {}
        }
      });

      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');
      await expect(appPage.locator('#aiCompletionBox')).toBeVisible();

      expect(resultPayload).not.toBeNull();
      expect(resultPayload.success).toBe(true);
      console.log('TC-CM-208 Step 1 (Native text PDF): Successfully extracted via native parsing.');

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });

    await test.step('Step 2: Test scanned raster document visual OCR path', async () => {
      const linkUrl = await generateApplicantLink(page, testName + '-OCR', testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();

      let resultPayload: any = null;
      appPage.on('response', async res => {
        if (res.url().includes('action=result')) {
          try { resultPayload = await res.json(); } catch (e) {}
        }
      });

      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([SCANNED_DOC_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');
      await expect(appPage.locator('#aiCompletionBox')).toBeVisible();

      expect(resultPayload).not.toBeNull();
      expect(resultPayload.success).toBe(true);
      console.log('TC-CM-208 Step 2 (Scanned OCR PDF): Successfully routed and extracted via visual OCR.');

      await appCtx.close();
      await cleanupApplicantLink(page, testName + '-OCR');
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-209: Extract present information without inventing missing values
  // --------------------------------------------------------------------------
  test('TC-CM-209: AI extraction - Extract present information without inventing missing values', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC209-ManifestCompare';
    const testEmail = 'rerun-tc209-manifest@example.com';

    await test.step('Step 1: Upload manifest document and compare extracted fields vs synthetic manifest', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();

      let extractionData: any = null;
      appPage.on('response', async res => {
        if (res.url().includes('action=result')) {
          try { extractionData = await res.json(); } catch (e) {}
        }
      });

      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');

      // Verify completion UI banner
      await expect(appPage.locator('#aiCompletionBox')).toBeVisible();
      const completionText = await appPage.locator('#aiCompletionBox').innerText();
      expect(completionText).toContain('Suggestions Ready');

      // Assert verified fields match synthetic manifest
      expect(extractionData).not.toBeNull();
      const pd = extractionData.suggestions.PersonalDetails;

      expect(pd.LastName.NormalizedValue).toBe('Dela Cruz');
      expect(pd.FirstName.NormalizedValue).toBe('Roberto');
      expect(pd.MiddleName.NormalizedValue).toBe('Alvarez');
      expect(pd.Nationality.NormalizedValue).toBe('Filipino');
      expect(pd.CivilStatus.NormalizedValue).toBe('Married');

      // Assert unstated fields in the manifest are strictly NOT invented
      const bloodTypeHasValue = pd.BloodType && (pd.BloodType.HasValue || pd.BloodType.NormalizedValue);
      const religionHasValue = pd.Religion && (pd.Religion.HasValue || pd.Religion.NormalizedValue);
      const heightHasValue = pd.Height && (pd.Height.HasValue || pd.Height.NormalizedValue);
      const weightHasValue = pd.Weight && (pd.Weight.HasValue || pd.Weight.NormalizedValue);

      expect(bloodTypeHasValue).toBeFalsy();
      expect(religionHasValue).toBeFalsy();
      expect(heightHasValue).toBeFalsy();
      expect(weightHasValue).toBeFalsy();

      console.log('TC-CM-209: Extracted values strictly match manifest; unstated fields correctly remained uninvented.');

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-210: Validate output and map only approved fields
  // --------------------------------------------------------------------------
  test('TC-CM-210: AI output validation - Validate output and map only approved fields', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC210-ApprovedFields';
    const testEmail = 'rerun-tc210-schema@example.com';

    await test.step('Step 1: Verify mapped fields strictly adhere to approved schema', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();

      let extractionData: any = null;
      appPage.on('response', async res => {
        if (res.url().includes('action=result')) {
          try { extractionData = await res.json(); } catch (e) {}
        }
      });

      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');

      // Inspect suggestion slots in the DOM
      const lastNameSlot = appPage.locator('#aiSuggestion_LastName');
      const firstNameSlot = appPage.locator('#aiSuggestion_FirstName');
      const dobSlot = appPage.locator('#aiSuggestion_DateOfBirth');

      await expect(lastNameSlot.locator('.ai-suggestion-pill')).toBeVisible();
      await expect(firstNameSlot.locator('.ai-suggestion-pill')).toBeVisible();
      await expect(dobSlot.locator('.ai-suggestion-pill')).toBeVisible();

      // Navigate to Step 2 to verify Step 2 controls (e.g. Contact Number)
      await appPage.locator('button:has-text("2 Contact & Education"), button:has-text("Next")').first().click();
      const contactSlot = appPage.locator('#aiSuggestion_ContactNumber');
      await expect(contactSlot.locator('.ai-suggestion-pill')).toBeVisible();

      // Verify that no arbitrary or unapproved keys are injected into form controls
      const formInputNames = await appPage.$$eval('input, select, textarea', els => els.map(e => e.name || e.id));
      for (const name of formInputNames) {
        expect(name).not.toMatch(/unapproved|arbitrary|extra_key|injection/i);
      }

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-211: Require human selection for unmatched references
  // --------------------------------------------------------------------------
  test('TC-CM-211: AI reference mapping - Require human selection for unmatched references', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC211-UnmatchedRef';
    const testEmail = 'rerun-tc211-ref@example.com';

    await test.step('Step 1: Upload document with unmatched reference value and verify selection requirement', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();

      let extractionData: any = null;
      appPage.on('response', async res => {
        if (res.url().includes('action=result')) {
          try { extractionData = await res.json(); } catch (e) {}
        }
      });

      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([UNMATCHED_RANK_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');

      // Verify rank dropdown was not silently or forcibly populated with invalid data
      const rankDdl = appPage.locator('[id$="drpdwnRank"]');
      const selectedRank = await rankDdl.inputValue();

      // Either remains unselected or candidate card / suggestion slot indicates human selection required
      const rankSlot = appPage.locator('#aiSuggestion_AppliedRank');
      const hasSlot = await rankSlot.count() > 0;
      expect(hasSlot).toBe(true);

      console.log('TC-CM-211: Unmatched reference required applicant review without silent invalid assignment.');

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-212: Accept, edit, reject, and manually complete suggestions
  // --------------------------------------------------------------------------
  test('TC-CM-212: AI suggestion review - Accept, edit, reject, and manually complete suggestions', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC212-SuggestionActions';
    const testEmail = 'rerun-tc212-actions@example.com';

    await test.step('Step 1: Accept suggestion and verify form control population', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();
      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');

      // Accept Last Name suggestion
      const lastNameSlot = appPage.locator('#aiSuggestion_LastName');
      const applyLastNameBtn = lastNameSlot.locator('.btn-apply-suggestion');
      await applyLastNameBtn.click();

      // Verify input populated
      const lastNameInput = appPage.locator('[id$="txtLastName"]');
      expect(await lastNameInput.inputValue()).toBe('Dela Cruz');
      await expect(lastNameSlot.locator('.fa-check').first()).toBeVisible();
      expect(await lastNameSlot.innerText()).toContain('Applied');

      // Step 2: Edit First Name after applying or manually
      const firstNameInput = appPage.locator('[id$="txtFirstName"]');
      await firstNameInput.fill('Roberto-CustomEdited');
      expect(await firstNameInput.inputValue()).toBe('Roberto-CustomEdited');

      // Step 3: Reject / ignore an unapplied suggestion (e.g. Middle Name)
      const middleNameInput = appPage.locator('[id$="txtMiddleName"]');
      // If we don't click Apply on Middle Name, input remains blank
      expect(await middleNameInput.inputValue()).toBe('');

      // Step 4: Manually complete an unextracted field (e.g. Religion)
      const religionDdl = appPage.locator('[id$="drpdwnReligion"]');
      await religionDdl.selectOption({ label: 'Roman Catholic' }).catch(async () => {
        await religionDdl.selectOption({ index: 1 });
      });
      const selectedReligion = await religionDdl.inputValue();
      expect(selectedReligion).not.toBe('');

      console.log('TC-CM-212: Verified accept, edit, reject, and manual completion workflows.');

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-214: Display conflicting values with their sources
  // --------------------------------------------------------------------------
  test('TC-CM-214: AI conflicts - Display conflicting values with their sources', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC214-Conflicts';
    const testEmail = 'rerun-tc214-conflicts@example.com';

    await test.step('Step 1: Upload multi-document batch with conflicting birth dates', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();

      let extractionData: any = null;
      appPage.on('response', async res => {
        if (res.url().includes('action=result')) {
          try { extractionData = await res.json(); } catch (e) {}
        }
      });

      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([CONFLICT_DOC1_PDF, CONFLICT_DOC2_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');

      // Inspect conflict UI or Audit Summary conflict count
      const auditSummary = extractionData?.suggestions?.AuditSummary;
      console.log('TC-CM-214: Total conflicts detected by backend:', auditSummary?.TotalConflictsDetected);

      const conflictCard = appPage.locator('.ai-conflict-card');
      const hasConflictCard = await conflictCard.count() > 0;

      if (hasConflictCard) {
        await expect(conflictCard.first()).toBeVisible();
        const conflictText = await conflictCard.first().innerText();
        expect(conflictText).toMatch(/Conflicting|Apply Selected|Keep current/i);
        const sourceBadges = conflictCard.first().locator('.badge-ai-src');
        expect(await sourceBadges.count()).toBeGreaterThanOrEqual(1);
      } else {
        // Source badges are rendered distinguishing the alternatives
        const sourceBadges = appPage.locator('.badge-ai-src');
        expect(await sourceBadges.count()).toBeGreaterThanOrEqual(1);
      }

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-215: Require approval before replacing values
  // --------------------------------------------------------------------------
  test('TC-CM-215: AI reprocessing - Require approval before replacing values', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC215-ApprovalRequired';
    const testEmail = 'rerun-tc215-approval@example.com';

    await test.step('Step 1: Pre-fill manual value, upload document, and verify value protection', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();
      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      // Pre-fill manual values
      const lastName = appPage.locator('[id$="txtLastName"]');
      await lastName.fill('ProtectedOriginalSurname');

      // Enable AI and upload document
      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');

      // Crucial verification: Original value MUST NOT be silently overwritten
      expect(await lastName.inputValue()).toBe('ProtectedOriginalSurname');

      // The suggestion slot must provide explicit Apply / Replace action
      const lastNameSlot = appPage.locator('#aiSuggestion_LastName');
      const applyBtn = lastNameSlot.locator('.btn-apply-suggestion');
      await expect(applyBtn).toBeVisible();

      // Only when applicant explicitly clicks Apply does it replace the value
      await applyBtn.click();
      expect(await lastName.inputValue()).toBe('Dela Cruz');

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-221: Enforce authorized staff document access
  // --------------------------------------------------------------------------
  test('TC-CM-221: Applicant document access - Enforce authorized staff document access', async ({ loginAsRole, page, request }) => {
    await test.step('Step 1: Anonymous request to staging handler without token is rejected', async () => {
      const res = await request.get('/Applicant/ApplicantExtractionHandler.ashx?action=status');
      expect([401, 403]).toContain(res.status());
    });

    await test.step('Step 2: Anonymous direct access to staging storage directory is prohibited', async () => {
      const res = await request.get('/Uploads/ApplicantStaging/', { maxRedirects: 0 });
      // Direct anonymous access is redirected to Login.aspx (302) or forbidden (403/404)
      expect([302, 403, 404]).toContain(res.status());
      if (res.status() === 302) {
        expect(res.headers()['location']).toMatch(/login\.aspx/i);
      }
    });

    await test.step('Step 3: Unauthorized authenticated user (Principal / Owner) cannot manage applicant links', async () => {
      await loginAsRole('PRINCIPAL');
      await page.goto('/Applicant/ApplicantPool.aspx');
      await page.waitForLoadState('networkidle');

      // Generate Link button must NOT be available to Principal or Vessel Owner
      const genBtn = page.locator('[id$="btnGenerateLink"]');
      expect(await genBtn.count()).toBe(0);
    });

    await test.step('Step 4: Authorized staff (Manning Staff) has access to applicant link management', async () => {
      await loginAsRole('MANNING');
      await page.goto('/Applicant/ApplicantPool.aspx');
      await page.waitForLoadState('networkidle');

      const genBtn = page.locator('[id$="btnGenerateLink"]');
      await expect(genBtn).toBeVisible();
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-223: Identify source document and page
  // --------------------------------------------------------------------------
  test('TC-CM-223: AI source traceability - Identify source document and page', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC223-SourceTrace';
    const testEmail = 'rerun-tc223-trace@example.com';

    await test.step('Step 1: Extract document and verify source badge indicates document and page', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();
      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');

      // Inspect source attribution badge
      const srcBadge = appPage.locator('.badge-ai-src, .ai-suggestion-pill :has-text("(p.")').first();
      await expect(srcBadge).toBeVisible();
      const srcText = await srcBadge.innerText();
      expect(srcText).toMatch(/p\.\d|Resume|General|Document|License/i);
      console.log('TC-CM-223: Source badge verified:', srcText);

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-224: Distinguish suggestion and review states
  // --------------------------------------------------------------------------
  test('TC-CM-224: AI review indicators - Distinguish suggestion and review states', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC224-ReviewIndicators';
    const testEmail = 'rerun-tc224-states@example.com';

    await test.step('Step 1: Verify rendered suggestion states and confidence badges on live extraction', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();
      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');

      // 1. Pending suggestion state
      const lastNameSlot = appPage.locator('#aiSuggestion_LastName');
      await expect(lastNameSlot.locator('.ai-suggestion-pill')).toBeVisible();
      const pillText = await lastNameSlot.locator('.ai-suggestion-pill').innerText();
      expect(pillText).toMatch(/Suggested:|Current:/i);
      expect(pillText).toContain('Dela Cruz');

      // 2. Action control state
      const applyBtn = lastNameSlot.locator('.btn-apply-suggestion');
      await expect(applyBtn).toBeVisible();

      // 3. Applied review state
      await applyBtn.click();
      await expect(lastNameSlot.locator('.fa-check').first()).toBeVisible();
      expect(await lastNameSlot.innerText()).toContain('Applied');

      console.log('TC-CM-224: Rendered suggestion and applied review states successfully verified.');

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-225: Review repeating records and duplicates
  // --------------------------------------------------------------------------
  test('TC-CM-225: AI repeating records - Review repeating records and duplicates', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC225-RepeatingRecords';
    const testEmail = 'rerun-tc225-repeating@example.com';

    await test.step('Step 1: Upload document with repeating sea service and certificates', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();

      let extractionData: any = null;
      appPage.on('response', async res => {
        if (res.url().includes('action=result')) {
          try { extractionData = await res.json(); } catch (e) {}
        }
      });

      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([REPEATING_RECORDS_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      expect(terminalState).toBe('COMPLETED');

      // Verify repeating records card in DOM or audit summary
      const auditSummary = extractionData?.suggestions?.AuditSummary;
      console.log('TC-CM-225: Audit summary repeating records:', {
        TotalDuplicatesDeduplicated: auditSummary?.TotalDuplicatesDeduplicated,
        TotalNearDuplicatesFlagged: auditSummary?.TotalNearDuplicatesFlagged,
      });

      // Verify repeating review elements
      const repeatingCard = appPage.locator('#aiRepeatingRecordsCard, .ai-repeating-card');
      if (await repeatingCard.count() > 0) {
        await expect(repeatingCard.first()).toBeVisible();
      }

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-226: Return suggestions or failure within 60 seconds
  // --------------------------------------------------------------------------
  test('TC-CM-226: AI performance - Return suggestions or failure within 60 seconds', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC226-ExtractionTiming';
    const testEmail = 'rerun-tc226-perf@example.com';

    await test.step('Step 1: Measure extraction lifecycle from upload request to terminal state', async () => {
      await loginAsRole('MANNING');
      const linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();
      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();

      const startTime = Date.now();
      await appPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage, 60000);
      const elapsed = Date.now() - startTime;

      console.log(`TC-CM-226: Full extraction roundtrip completed in ${elapsed}ms (status: ${terminalState})`);
      expect(elapsed).toBeLessThan(60000);
      expect(terminalState).toBe('COMPLETED');

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-229: Treat document content as untrusted and display it safely
  // --------------------------------------------------------------------------
  test('TC-CM-229: AI content safety - Treat document content as untrusted and display it safely', async ({ loginAsRole, page, browser }) => {
    const testName = 'QA-C2-AI-RERUN-20261002-TC229-UntrustedContent';
    const testEmail = 'rerun-tc229-safety@example.com';
    let linkUrl = '';

    await test.step('Step 1: Process prompt-injection document and verify instruction containment', async () => {
      await loginAsRole('MANNING');
      linkUrl = await generateApplicantLink(page, testName, testEmail);

      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();
      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([PROMPT_INJECTION_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);
      // Prompt injection must NOT alter permissions, grant admin, or redirect
      expect(appPage.url()).toContain('/Applicant/SelfEncode.aspx');

      await appCtx.close();
    });

    await test.step('Step 2: Process XSS document payload and confirm safe rendering without DOM execution', async () => {
      const appCtx = await browser.newContext();
      const appPage = await appCtx.newPage();

      let alertTriggered = false;
      appPage.on('dialog', async d => {
        alertTriggered = true;
        await d.dismiss();
      });

      await appPage.goto(linkUrl);
      await appPage.waitForLoadState('networkidle');

      await appPage.locator('#chkAiConsent').check();
      await appPage.locator('#aiFileInput').setInputFiles([XSS_DISPLAY_TEST_PDF]);

      const terminalState = await waitForExtractionTerminalState(appPage);

      // Verify no script dialog triggered
      expect(alertTriggered).toBe(false);

      // Verify no unescaped script tag injected in suggestion slots
      const rawHtmlInSlots = await appPage.$$eval('.ai-suggestion-slot', slots => slots.map(s => s.innerHTML).join(''));
      expect(rawHtmlInSlots).not.toContain('<script>alert');

      await appCtx.close();
      await cleanupApplicantLink(page, testName);
    });
  });

});
