import { test, expect } from '../../fixtures/auth.fixture';
import { Page } from '@playwright/test';
import path from 'path';
import fs from 'fs';

const PREFIX = 'QA-C2-TC212-FINAL-20261004';
const FIXTURES_DIR = path.resolve(__dirname, '../../test-data/ai-fixtures');
const MANIFEST_RESUME_PDF = path.join(FIXTURES_DIR, 'synthetic_manifest_resume.pdf');

function getTomorrowDateString(daysAhead = 2): string {
  const d = new Date();
  d.setDate(d.getDate() + daysAhead);
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
  await page.locator('[id$="txtLinkValidity"]').fill(getTomorrowDateString(2));

  await page.locator('[id$="btnCreateLink"]').click();
  await page.waitForLoadState('networkidle').catch(() => {});

  const linkInput = page.locator('[id$="txtGeneratedLink"]');
  await expect(linkInput).toBeVisible({ timeout: 10000 });
  const rawUrl = await linkInput.inputValue();
  return rawUrl.replace(/^https?:\/\/[^\/]+/, '');
}

async function cleanupApplicantLink(page: Page, applicantName: string) {
  try {
    await page.goto('/Applicant/ApplicantPool.aspx');
    await page.waitForLoadState('networkidle').catch(() => {});

    page.on('dialog', async d => {
      await d.accept().catch(() => {});
    });

    const isAlreadyVisible = await page.locator('[id$="panelManageLinks"]').isVisible().catch(() => false);
    if (!isAlreadyVisible) {
      const manageBtn = page.locator('[id$="btnManageLinks"]');
      await Promise.all([
        page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST').catch(() => {}),
        manageBtn.click(),
      ]);
      await page.waitForLoadState('networkidle').catch(() => {});
    }

    const row = page.locator(`[id$="gvLinks"] tr:has-text("${applicantName}")`).first();
    if (await row.count() > 0) {
      const ddl = row.locator('select[id*="drpdwnNewStatus"]');
      if (await ddl.isVisible().catch(() => false)) {
        await ddl.selectOption('Expired');
        const applyBtn = row.locator('a[id*="btnUpdateStatus"]');
        await Promise.all([
          page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST').catch(() => {}),
          applyBtn.click(),
        ]);
        await page.waitForTimeout(400);
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

test.describe('TC-CM-212: Post-Fix Formal Verification (Commit 97fd151 / b323bcd)', () => {
  test.setTimeout(180000);

  // ==========================================================================
  // PART 1: Apply, Replace, Edit, Manual Completion, and Content Safety
  // ==========================================================================
  test('TC-CM-212 Part 1: Apply, Replace, Edit, Manual Completion, Content Safety', async ({
    loginAsRole,
    page,
    browser,
  }) => {
    const applyTestName = `${PREFIX}-ApplySession`;
    const applyTestEmail = `postfix-apply-${Date.now()}@example.com`;
    let applyLinkUrl = '';

    await test.step('Phase Setup: Generate fresh applicant link', async () => {
      await loginAsRole('MANNING');
      applyLinkUrl = await generateApplicantLink(page, applyTestName, applyTestEmail);
      expect(applyLinkUrl).toBeTruthy();
    });

    const applyCtx = await browser.newContext();
    const applyPage = await applyCtx.newPage();

    let alertTriggered = false;
    applyPage.on('dialog', async d => {
      alertTriggered = true;
      await d.dismiss();
    });

    const pageErrors: string[] = [];
    applyPage.on('pageerror', err => {
      console.error('Part 1 PAGE_ERROR:', err.message);
      pageErrors.push(err.message);
    });

    await test.step('Upload resume and await extraction completion', async () => {
      await applyPage.goto(applyLinkUrl);
      await applyPage.waitForLoadState('networkidle');

      await applyPage.locator('#chkAiConsent').check();
      await applyPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const state = await waitForExtractionTerminalState(applyPage);
      expect(state).toBe('COMPLETED');
    });

    // ── A. Apply Lifecycle ───────────────────────────────────────────────────
    await test.step('A. Apply: Generate suggestion for empty field, apply it, verify destination received value and UI shows applied', async () => {
      const middleNameInput = applyPage.locator('[id$="txtMiddleName"]');
      expect(await middleNameInput.inputValue()).toBe('');

      const middleSlot = applyPage.locator('#aiSuggestion_MiddleName');
      await expect(middleSlot).toBeVisible({ timeout: 5000 });

      const applyBtn = middleSlot.locator('.btn-apply-suggestion');
      await expect(applyBtn).toBeVisible();
      const suggestedVal = await applyBtn.getAttribute('data-val');
      expect(suggestedVal).toBeTruthy();

      console.log(`[A. Apply] Applying suggested MiddleName: "${suggestedVal}"`);
      await applyBtn.click();

      // Destination field receives exact suggested value
      expect(await middleNameInput.inputValue()).toBe(suggestedVal);

      // UI displays applied state
      await expect(middleSlot.locator('.ai-suggestion-pill')).toHaveClass(/ai-sug-matched|ai-sug-applied/);
      await expect(middleSlot.locator('.ai-suggestion-pill')).toContainText(/Applied:|Matches document:/i);
    });

    // ── B. Replace Lifecycle ─────────────────────────────────────────────────
    await test.step('B. Replace: Conflicting suggestion shows current and suggested values, apply Replace, verify destination', async () => {
      const lastNameInput = applyPage.locator('[id$="txtLastName"]');
      const currentLastName = await lastNameInput.inputValue();
      expect(currentLastName).toContain(PREFIX);

      const lastSlot = applyPage.locator('#aiSuggestion_LastName');
      await expect(lastSlot).toBeVisible();

      // Shows current and suggested values
      const pill = lastSlot.locator('.ai-suggestion-pill');
      await expect(pill).toHaveClass(/ai-sug-different/);
      await expect(pill.locator('.ai-curr-val')).toContainText(currentLastName);

      // Explicit Replace button
      const replaceBtn = lastSlot.locator('.btn-replace-suggestion');
      await expect(replaceBtn).toBeVisible();
      const proposedLastName = await replaceBtn.getAttribute('data-val');
      expect(proposedLastName).toBeTruthy();

      console.log(`[B. Replace] Replacing LastName: "${currentLastName}" -> "${proposedLastName}"`);
      await replaceBtn.click();

      // Destination field receives proposed value
      expect(await lastNameInput.inputValue()).toBe(proposedLastName);
    });

    // ── C. Edit Lifecycle ────────────────────────────────────────────────────
    await test.step('C. Edit: Manually edit applied value, navigate wizard steps, verify edit intact', async () => {
      const middleNameInput = applyPage.locator('[id$="txtMiddleName"]');
      const editedVal = 'Alvarez-EditedManual-2026';

      await middleNameInput.fill(editedVal);
      expect(await middleNameInput.inputValue()).toBe(editedVal);

      // Navigate to Step 2
      const step2Btn = applyPage.locator('.stepper-step:has-text("2"), button:has-text("Next")').first();
      await step2Btn.click();
      await applyPage.waitForTimeout(800);

      // Navigate back to Step 1
      const step1Btn = applyPage.locator('.stepper-step:has-text("1"), button:has-text("Back")').first();
      await step1Btn.click();
      await applyPage.waitForTimeout(800);

      // Confirm manual edit remains intact
      expect(await middleNameInput.inputValue()).toBe(editedVal);
      console.log(`[C. Edit] MiddleName preserved after wizard navigation: "${editedVal}"`);
    });

    // ── G. Manual Completion ─────────────────────────────────────────────────
    await test.step('G. Manual Completion: Fill empty field manually, verify preserved across steps', async () => {
      const birthPlaceInput = applyPage.locator('[id$="txtPOB"], [id$="txtPlaceOfBirth"]');
      const manualBirthPlace = 'Zamboanga City';

      await birthPlaceInput.fill(manualBirthPlace);
      expect(await birthPlaceInput.inputValue()).toBe(manualBirthPlace);

      // Navigate forward and backward
      const step2Btn = applyPage.locator('.stepper-step:has-text("2"), button:has-text("Next")').first();
      await step2Btn.click();
      await applyPage.waitForTimeout(800);

      const step1Btn = applyPage.locator('.stepper-step:has-text("1"), button:has-text("Back")').first();
      await step1Btn.click();
      await applyPage.waitForTimeout(800);

      expect(await birthPlaceInput.inputValue()).toBe(manualBirthPlace);
    });

    // ── H. Content Safety ────────────────────────────────────────────────────
    await test.step('H. Content Safety: Confirm zero script execution and inert HTML escaping', async () => {
      expect(alertTriggered).toBe(false);

      const slotHtmlList = await applyPage.$$eval('.ai-suggestion-slot', slots => slots.map(s => s.innerHTML));
      for (const html of slotHtmlList) {
        expect(html).not.toContain('<script');
        expect(html).not.toContain('onerror=');
      }
    });

    // ── I. Zero JavaScript runtime errors ───────────────────────────────────
    await test.step('I. Zero JavaScript runtime errors during Apply/Replace/Edit', async () => {
      expect(pageErrors, `Expected 0 page errors, found: ${pageErrors.join(', ')}`).toHaveLength(0);
    });

    await applyCtx.close();
    await cleanupApplicantLink(page, applyTestName);
  });

  // ==========================================================================
  // PART 2: Explicit Scalar Reject, Conflicting Reject & Rejection Persistence
  // ==========================================================================
  test('TC-CM-212 Part 2: Explicit Scalar Reject, Conflicting Reject & Rejection Persistence', async ({
    loginAsRole,
    page,
    browser,
  }) => {
    const rejectTestName = `${PREFIX}-RejectSession`;
    const rejectTestEmail = `postfix-reject-${Date.now()}@example.com`;
    let rejectLinkUrl = '';

    await test.step('Setup: Generate fresh applicant link for rejection lifecycle', async () => {
      await loginAsRole('MANNING');
      rejectLinkUrl = await generateApplicantLink(page, rejectTestName, rejectTestEmail);
      expect(rejectLinkUrl).toBeTruthy();
    });

    const rejectCtx = await browser.newContext();
    const rejectPage = await rejectCtx.newPage();

    const pageErrors: string[] = [];
    rejectPage.on('pageerror', err => {
      console.error('Part 2 PAGE_ERROR:', err.message);
      pageErrors.push(err.message);
    });

    await test.step('Upload resume and await extraction completion', async () => {
      await rejectPage.goto(rejectLinkUrl);
      await rejectPage.waitForLoadState('networkidle');

      await rejectPage.locator('#chkAiConsent').check();
      await rejectPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const state = await waitForExtractionTerminalState(rejectPage);
      expect(state).toBe('COMPLETED');
    });

    // ── D. Ordinary Scalar Reject (Empty field suggestion) ───────────────────
    await test.step('D. Ordinary Scalar Reject: Reject empty field suggestion, verify destination empty, pill rejected, zero JS errors', async () => {
      const middleNameInput = rejectPage.locator('[id$="txtMiddleName"]');
      expect(await middleNameInput.inputValue()).toBe('');

      const middleSlot = rejectPage.locator('#aiSuggestion_MiddleName');
      await expect(middleSlot).toBeVisible({ timeout: 5000 });

      // Confirm Reject button exists
      const rejectBtn = middleSlot.locator('.btn-reject-suggestion');
      await expect(rejectBtn).toBeVisible();
      expect(await rejectBtn.innerText()).toBe('Reject');

      console.log('[D. Reject] Clicking Reject on MiddleName suggestion...');
      await rejectBtn.click();
      await rejectPage.waitForTimeout(500);

      // Confirm destination field remains unchanged and empty
      expect(await middleNameInput.inputValue()).toBe('');

      // Confirm suggestion pill transitions to .ai-sug-rejected and displays "Rejected:"
      const rejectedPill = middleSlot.locator('.ai-suggestion-pill');
      await expect(rejectedPill).toHaveClass(/ai-sug-rejected/);
      await expect(rejectedPill).toContainText(/Rejected:/i);

      // Capture screenshot of post-fix verified rejection state
      const ssPath = 'test-results/tc212-final-retest/tc212-postfix-verified-scalar-rejection.png';
      fs.mkdirSync(path.dirname(path.resolve(__dirname, '../../', ssPath)), { recursive: true });
      await middleSlot.screenshot({ path: path.resolve(__dirname, '../../', ssPath) });
      console.log(`[D. Reject] Captured post-fix rejection screenshot at: ${ssPath}`);

      // Verify ZERO page errors occurred on reject click
      expect(pageErrors, `No runtime error expected on reject click: ${pageErrors.join(', ')}`).toHaveLength(0);
    });

    // ── E. Conflicting-Value Reject ──────────────────────────────────────────
    await test.step('E. Conflicting-Value Reject: Reject conflicting suggestion, verify manual value intact, pill rejected', async () => {
      const lastNameInput = rejectPage.locator('[id$="txtLastName"]');
      const currentLastName = await lastNameInput.inputValue();
      expect(currentLastName).toContain(PREFIX);

      const lastSlot = rejectPage.locator('#aiSuggestion_LastName');
      await expect(lastSlot).toBeVisible();

      // Pill shows conflict
      const pill = lastSlot.locator('.ai-suggestion-pill');
      await expect(pill).toHaveClass(/ai-sug-different/);

      // Find Reject button on conflict card
      const rejectBtn = lastSlot.locator('.btn-reject-suggestion');
      await expect(rejectBtn).toBeVisible();

      console.log('[E. Conflicting Reject] Clicking Reject on LastName conflicting suggestion...');
      await rejectBtn.click();
      await rejectPage.waitForTimeout(500);

      // Confirm manual value remains completely unchanged
      expect(await lastNameInput.inputValue()).toBe(currentLastName);

      // Confirm pill transitions to .ai-sug-rejected
      const rejectedPill = lastSlot.locator('.ai-suggestion-pill');
      await expect(rejectedPill).toHaveClass(/ai-sug-rejected/);
      await expect(rejectedPill).toContainText(/Rejected:/i);

      // Verify ZERO page errors
      expect(pageErrors).toHaveLength(0);
    });

    // ── F. Rejection Persistence across Wizard Navigation ────────────────────
    await test.step('F. Rejection Persistence: Navigate to Step 2 and return to Step 1, verify rejected state persists', async () => {
      const middleNameInput = rejectPage.locator('[id$="txtMiddleName"]');
      const lastNameInput = rejectPage.locator('[id$="txtLastName"]');
      const expectedLastName = await lastNameInput.inputValue();

      // Navigate to Step 2
      const step2Btn = rejectPage.locator('.stepper-step:has-text("2"), button:has-text("Next")').first();
      await step2Btn.click();
      await rejectPage.waitForTimeout(800);

      // Navigate back to Step 1
      const step1Btn = rejectPage.locator('.stepper-step:has-text("1"), button:has-text("Back")').first();
      await step1Btn.click();
      await rejectPage.waitForTimeout(800);

      // Destination fields remain unchanged
      expect(await middleNameInput.inputValue()).toBe('');
      expect(await lastNameInput.inputValue()).toBe(expectedLastName);

      // Slots still show rejected state
      const middleSlot = rejectPage.locator('#aiSuggestion_MiddleName');
      await expect(middleSlot.locator('.ai-suggestion-pill')).toHaveClass(/ai-sug-rejected/);
      await expect(middleSlot.locator('.ai-suggestion-pill')).toContainText(/Rejected:/i);

      const lastSlot = rejectPage.locator('#aiSuggestion_LastName');
      await expect(lastSlot.locator('.ai-suggestion-pill')).toHaveClass(/ai-sug-rejected/);
      await expect(lastSlot.locator('.ai-suggestion-pill')).toContainText(/Rejected:/i);

      console.log('[F. Persistence] Rejections successfully persisted across wizard navigation');
    });

    // ── G. Manual Completion after Rejection ─────────────────────────────────
    await test.step('G. Manual Entry after Rejection: Manually fill rejected field and navigate', async () => {
      const middleNameInput = rejectPage.locator('[id$="txtMiddleName"]');
      const manualEntry = 'Reyes-ManualPostReject';

      await middleNameInput.fill(manualEntry);
      expect(await middleNameInput.inputValue()).toBe(manualEntry);

      // Navigate to Step 2 and return
      const step2Btn = rejectPage.locator('.stepper-step:has-text("2"), button:has-text("Next")').first();
      await step2Btn.click();
      await rejectPage.waitForTimeout(800);

      const step1Btn = rejectPage.locator('.stepper-step:has-text("1"), button:has-text("Back")').first();
      await step1Btn.click();
      await rejectPage.waitForTimeout(800);

      expect(await middleNameInput.inputValue()).toBe(manualEntry);
    });

    // ── H. Final Error Check ─────────────────────────────────────────────────
    await test.step('H. Final Error Check: Ensure zero uncaught runtime errors across entire session', async () => {
      expect(pageErrors).toHaveLength(0);
    });

    // Capture full-page screenshot of completed verified rejection session
    const fullSsPath = 'test-results/tc212-final-retest/tc212-postfix-verified-fullpage.png';
    await rejectPage.screenshot({ path: path.resolve(__dirname, '../../', fullSsPath), fullPage: true });

    await rejectCtx.close();
    await cleanupApplicantLink(page, rejectTestName);
  });
});
