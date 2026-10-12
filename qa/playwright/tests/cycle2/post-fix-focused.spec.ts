import { test, expect } from '../../fixtures/auth.fixture';
import { Page } from '@playwright/test';
import path from 'path';
import fs from 'fs';

const PREFIX = 'QA-C2-POSTFIX-20261004';
const QA_VESSEL_A = 'QA-C2-RUN-20261001-C2P1-Vessel-A';
const QA_VESSEL_B = 'QA-C2-RUN-20261001-C2P1-Vessel-B';

const FIXTURES_DIR = path.resolve(__dirname, '../../test-data/ai-fixtures');
const MANIFEST_RESUME_PDF = path.join(FIXTURES_DIR, 'synthetic_manifest_resume.pdf');

function getTomorrowDateString(daysAhead = 1): string {
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

async function selectVessel(page: Page, vesselId: string) {
  let picker = page.locator('[id$="drpVesselPicker"]');
  if (!await picker.isVisible().catch(() => false)) {
    await page.goto('/Crew/CrewChangeList.aspx');
    await page.waitForLoadState('networkidle');
    picker = page.locator('[id$="drpVesselPicker"]');
  }
  if (await picker.isVisible().catch(() => false)) {
    await Promise.all([
      page.waitForNavigation({ waitUntil: 'load' }).catch(() => {}),
      picker.selectOption(vesselId),
    ]);
    await page.waitForLoadState('networkidle');
  }
}

test.describe('UMMI Cycle 2 — Post-Fix Focused Regression Suite', () => {

  // ==========================================================================
  // TEST 1-A: TC-CM-212 Apply, Replace, Edit, Manual Completion & Content Safety
  // ==========================================================================
  test('TEST 1-A: TC-CM-212 Apply, Replace, Edit, Manual Completion & Content Safety', async ({ loginAsRole, page, browser }) => {
    const applyTestName = `${PREFIX}-TC212-ApplySession`;
    const applyTestEmail = `postfix-apply-${Date.now()}@example.com`;
    let applyLinkUrl = '';

    await test.step('Phase Setup: Initialize fresh applicant session for Apply, Replace, and Edit', async () => {
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

    await test.step('Step 1: Upload resume in fresh session and await extraction', async () => {
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

      console.log(`TEST 1-A [A. Apply] Applying suggested MiddleName: "${suggestedVal}"`);
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

      console.log(`TEST 1-A [B. Replace] Replacing LastName: "${currentLastName}" -> "${proposedLastName}"`);
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
      await applyPage.waitForTimeout(1000);

      // Navigate back to Step 1
      const step1Btn = applyPage.locator('.stepper-step:has-text("1"), button:has-text("Back")').first();
      await step1Btn.click();
      await applyPage.waitForTimeout(1000);

      // Confirm manual edit remains intact
      expect(await middleNameInput.inputValue()).toBe(editedVal);
      console.log(`TEST 1-A [C. Edit] MiddleName preserved after wizard navigation: "${editedVal}"`);
    });

    // ── G. Manual Completion ─────────────────────────────────────────────────
    await test.step('G. Manual Completion: Fill empty field manually, verify preserved', async () => {
      const birthPlaceInput = applyPage.locator('[id$="txtPOB"], [id$="txtPlaceOfBirth"]');
      const manualBirthPlace = 'Zamboanga City';

      await birthPlaceInput.fill(manualBirthPlace);
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
      console.log('TEST 1-A [H. Content Safety] Confirmed zero script execution across all slots');
    });

    await applyCtx.close();
    await cleanupApplicantLink(page, applyTestName);
  });

  // ==========================================================================
  // TEST 1-B: TC-CM-212 Explicit Reject, Conflicting Reject & Persistence (Commit c737536 Fix Verification)
  // ==========================================================================
  test('TEST 1-B: TC-CM-212 Explicit Reject, Conflicting Reject & Persistence (Commit c737536 Fix Verification)', async ({ loginAsRole, page, browser }) => {
    const rejectTestName = `${PREFIX}-TC212-RejectSession`;
    const rejectTestEmail = `postfix-reject-${Date.now()}@example.com`;
    let rejectLinkUrl = '';

    await test.step('Setup: Initialize applicant session for rejection lifecycle', async () => {
      await loginAsRole('MANNING');
      rejectLinkUrl = await generateApplicantLink(page, rejectTestName, rejectTestEmail);
      expect(rejectLinkUrl).toBeTruthy();
    });

    const rejectCtx = await browser.newContext();
    const rejectPage = await rejectCtx.newPage();

    const pageErrors: string[] = [];
    rejectPage.on('pageerror', err => {
      console.error('TEST 1-B BROWSER_PAGE_ERROR:', err.message);
      pageErrors.push(err.message);
    });

    await test.step('Step 1: Upload resume and await extraction completion', async () => {
      await rejectPage.goto(rejectLinkUrl);
      await rejectPage.waitForLoadState('networkidle');

      await rejectPage.locator('#chkAiConsent').check();
      await rejectPage.locator('#aiFileInput').setInputFiles([MANIFEST_RESUME_PDF]);

      const state = await waitForExtractionTerminalState(rejectPage);
      expect(state).toBe('COMPLETED');
    });

    // ── D. Reject Lifecycle (Empty Field Suggestion) ─────────────────────────
    await test.step('D. Reject: Verify explicit Reject control on empty field suggestion, reject it, verify empty destination and rejected UI', async () => {
      const middleNameInput = rejectPage.locator('[id$="txtMiddleName"]');
      expect(await middleNameInput.inputValue()).toBe('');

      const middleSlot = rejectPage.locator('#aiSuggestion_MiddleName');
      await expect(middleSlot).toBeVisible({ timeout: 5000 });

      // Confirm explicit Reject control appears (added in commit c737536)
      const rejectBtn = middleSlot.locator('.btn-reject-suggestion');
      await expect(rejectBtn).toBeVisible();
      expect(await rejectBtn.innerText()).toBe('Reject');

      // Click Reject
      await rejectBtn.click();
      await rejectPage.waitForTimeout(1000);

      // Confirm destination field remains unchanged and empty
      expect(await middleNameInput.inputValue()).toBe('');

      // Capture screenshot of scalar slot at reject state
      const ssPath = 'test-results/post-fix-focused-rerun/tc212-scalar-rejection-state.png';
      fs.mkdirSync(path.dirname(path.resolve(__dirname, '../../', ssPath)), { recursive: true });
      await middleSlot.screenshot({ path: path.resolve(__dirname, '../../', ssPath) });
      console.log(`TEST 1-B [D. Reject] Captured screenshot at: ${ssPath}`);

      if (pageErrors.length > 0) {
        console.error(`TEST 1-B [D. Reject] Runtime errors captured during reject click:`, pageErrors);
      }

      // Assert suggestion pill transitions to .ai-sug-rejected
      const rejectedPill = middleSlot.locator('.ai-suggestion-pill');
      const pillClass = await rejectedPill.getAttribute('class');
      expect(
        pillClass,
        `APPLICATION DEFECT in commit c737536: rejectSuggestion() threw "${pageErrors.join('; ')}" ` +
        `because this.saveState() / this.evaluateField() do not exist on ApplicantAiAssist. ` +
        `As a result, clicking Reject failed to transition the pill to .ai-sug-rejected!`
      ).toContain('ai-sug-rejected');
    });

    await rejectCtx.close();
    await cleanupApplicantLink(page, rejectTestName);
  });

  // ==========================================================================
  // TEST 2: Create Schedule Popup Crew Names Verification
  // ==========================================================================
  test('TEST 2: Create Schedule Popup Crew Names Verification & Tentative Schedule Save', async ({ loginAsRole, page }) => {
    await test.step('Step 1: Manning Staff navigates to Vessel B and prepares eligible nomination', async () => {
      await loginAsRole('MANNING');
      await selectVessel(page, '6'); // QA-VESSEL-B

      const rows = page.locator('#tblCCL tbody tr');
      const bonifacioRow = rows.filter({ hasText: 'Bonifacio' }).first();
      await expect(bonifacioRow).toBeVisible();

      // Check if Reliever button is visible (no active nomination yet)
      const relBtn = bonifacioRow.locator('button:has-text("Reliever")');
      if (await relBtn.isVisible()) {
        await relBtn.click();
        const modalRel = page.locator('#modalAddReliever');
        await expect(modalRel).toBeVisible();

        // Search blank to retrieve all eligible candidates
        await page.locator('[id$="txtRelieverSearch"]').fill('');
        await Promise.all([
          page.waitForNavigation({ waitUntil: 'load' }).catch(() => {}),
          page.locator('[id$="btnSearchReliever"]').click(),
        ]);
        await page.waitForLoadState('networkidle');

        const drpPick = page.locator('[id$="drpRelieverPick"]');
        const opts = await drpPick.locator('option').allInnerTexts();
        console.log(`TEST 2 Total Relievers available: ${opts.length - 1}`);
        expect(opts.length).toBeGreaterThan(1);

        // Select first available eligible candidate
        await drpPick.selectOption({ index: 1 });
        const selectedRelieverText = await drpPick.locator('option:checked').innerText();
        console.log(`TEST 2 Selected Reliever for Bonifacio: "${selectedRelieverText}"`);

        page.once('dialog', async d => await d.accept());
        await page.locator('[id$="btnConfirmReliever"]').click();
        await page.waitForLoadState('networkidle');
      }
    });

    await test.step('Step 2: SuperAdmin approves nomination if pending', async () => {
      await loginAsRole('SUPERADMIN');
      await selectVessel(page, '6');

      const bonifacioRow = page.locator('#tblCCL tbody tr').filter({ hasText: 'Bonifacio' }).first();
      const approveBtn = bonifacioRow.locator('button:has-text("Approve")');
      if (await approveBtn.isVisible()) {
        await approveBtn.click();
        const modalApprove = page.locator('#modalApproval');
        await expect(modalApprove).toBeVisible();

        await page.locator('[id$="txtApprovalRemarks"]').fill('Approved for post-fix CCL regression test');
        page.once('dialog', async d => await d.accept());
        await page.locator('[id$="btnConfirmApprove"]').click();
        await page.waitForLoadState('networkidle');
      }

      await expect(bonifacioRow.locator('td:nth-child(5)')).toContainText(/Approved/i);
    });

    await test.step('Step 3: Manning Staff opens Create Schedule popup and verifies crew names', async () => {
      await loginAsRole('MANNING');
      await selectVessel(page, '6');

      const bonifacioRow = page.locator('#tblCCL tbody tr').filter({ hasText: 'Bonifacio' }).first();
      const schedBtn = bonifacioRow.locator('button:has-text("Schedule")');
      // Open Create Schedule modal (via Schedule button or opener if already tentative)
      if (await schedBtn.isVisible()) {
        await schedBtn.click();
      } else {
        await page.evaluate(() => {
          const row = document.querySelector('#tblCCL tbody tr') as HTMLTableRowElement;
          const btn = row.querySelector('button') as HTMLButtonElement;
          // @ts-ignore
          if (typeof openCreateSchedule === 'function') openCreateSchedule(btn);
        });
      }
      const modal = page.locator('#modalSchedule');
      await expect(modal).toBeVisible();

      // Capture screenshot of Create Schedule popup names
      const ssPath = 'test-results/post-fix-focused-rerun/create-schedule-popup-names.png';
      fs.mkdirSync(path.dirname(path.resolve(__dirname, '../../', ssPath)), { recursive: true });
      await modal.screenshot({ path: path.resolve(__dirname, '../../', ssPath) });
      console.log(`TEST 2 Captured screenshot at: ${ssPath}`);

      // Verify Outgoing Crew label
      const targetLabel = page.locator('[id$="lblSchedTarget"]');
      const targetLabelText = await targetLabel.innerText();
      const targetLabelHtml = await targetLabel.innerHTML();
      console.log(`TEST 2 Create Schedule Target Label: "${targetLabelText}" (HTML: ${targetLabelHtml})`);

      // Strong assertions: Outgoing crew MUST match Andres Bonifacio
      expect(targetLabelText).toContain('Outgoing Crew:');
      expect(targetLabelText).toContain('Bonifacio, QA Andres de Castro');
      expect(targetLabelText).not.toContain('undefined');
      expect(targetLabelText.trim()).not.toBe('Outgoing Crew:');

      // Verify schedule modal title
      const modalTitle = await page.locator('#schedModalTitle').innerText();
      expect(modalTitle).toContain('Create CCL Schedule');

      // If schedBtn was visible, save the schedule; if already saved, close modal cleanly
      if (await schedBtn.isVisible()) {
        const joiningDate = getTomorrowDateString(7);
        const departureDate = getTomorrowDateString(7);
        const onsignDate = getTomorrowDateString(7);
        const joiningPort = 'Batangas Port';

        await page.locator('[id$="txtJoiningDate"]').fill(joiningDate);
        await page.locator('[id$="txtJoiningPort"]').fill(joiningPort);
        await page.locator('[id$="txtDepartureDate"]').fill(departureDate);
        await page.locator('[id$="txtShipOnsign"]').fill(onsignDate);

        page.once('dialog', async d => await d.accept());
        await page.locator('[id$="btnSaveSchedule"]').click();
        await page.waitForLoadState('networkidle');

        // Verify success notification
        const notify = page.locator('[id$="lblNotify"]');
        await expect(notify).toContainText(/successfully/i);
      } else {
        await modal.locator('button:has-text("Cancel")').click();
        await expect(modal).toBeHidden();
      }

      // Verify status is now Tentative
      const updatedRow = page.locator('#tblCCL tbody tr').filter({ hasText: 'Bonifacio' }).first();
      await expect(updatedRow.locator('td:nth-child(10)')).toContainText(/Tentative/i);

      // Confirm unrelated nominations on Vessel A were unchanged
      await selectVessel(page, '5'); // QA-VESSEL-A
      const santosRow = page.locator('#tblCCL tbody tr').filter({ hasText: 'Santos' }).first();
      await expect(santosRow.locator('td:nth-child(10)')).toContainText(/Next/i);
    });
  });

  // ==========================================================================
  // TEST 3: Edit Schedule Popup Crew Names Verification
  // ==========================================================================
  test('TEST 3: Edit Schedule Popup Crew Names Verification & Schedule Amendment', async ({ loginAsRole, page }) => {
    await test.step('Step 1: Manning Staff opens Edit Schedule on Tentative nomination', async () => {
      await loginAsRole('MANNING');
      await selectVessel(page, '6'); // QA-VESSEL-B

      const bonifacioRow = page.locator('#tblCCL tbody tr').filter({ hasText: 'Bonifacio' }).first();
      await expect(bonifacioRow.locator('td:nth-child(10)')).toContainText(/Tentative/i);

      const editBtn = bonifacioRow.locator('button:has-text("Edit")');
      await expect(editBtn).toBeVisible();

      // Open Edit Schedule
      await editBtn.click();
      const modal = page.locator('#modalSchedule');
      await expect(modal).toBeVisible();

      // Capture screenshot of Edit Schedule popup names
      const ssPath = 'test-results/post-fix-focused-rerun/edit-schedule-popup-names.png';
      fs.mkdirSync(path.dirname(path.resolve(__dirname, '../../', ssPath)), { recursive: true });
      await modal.screenshot({ path: path.resolve(__dirname, '../../', ssPath) });
      console.log(`TEST 3 Captured screenshot at: ${ssPath}`);

      // Verify modal title
      const modalTitle = await page.locator('#schedModalTitle').innerText();
      expect(modalTitle).toContain('Edit CCL Schedule');

      // Verify Outgoing Crew label
      const targetLabel = page.locator('[id$="lblSchedTarget"]');
      const targetLabelText = await targetLabel.innerText();
      const targetLabelHtml = await targetLabel.innerHTML();
      console.log(`TEST 3 Edit Schedule Target Label: "${targetLabelText}" (HTML: ${targetLabelHtml})`);

      // Strong assertions: Outgoing crew MUST match Andres Bonifacio
      expect(targetLabelText).toContain('Outgoing Crew:');
      expect(targetLabelText).toContain('Bonifacio, QA Andres de Castro');
      expect(targetLabelText).not.toContain('undefined');
      expect(targetLabelText.trim()).not.toBe('Outgoing Crew:');

      // Step 2: Amend joining port and dates, and save
      const amendedPort = 'Port of Subic';
      const amendedDate = getTomorrowDateString(9);

      await page.locator('[id$="txtJoiningPort"]').fill(amendedPort);
      await page.locator('[id$="txtJoiningDate"]').fill(amendedDate);
      await page.locator('[id$="txtDepartureDate"]').fill(amendedDate);
      await page.locator('[id$="txtShipOnsign"]').fill(amendedDate);

      page.once('dialog', async d => await d.accept());
      await page.locator('[id$="btnSaveSchedule"]').click();
      await page.waitForLoadState('networkidle');

      // Verify success notification
      const notify = page.locator('[id$="lblNotify"]');
      await expect(notify).toContainText(/successfully/i);

      // Verify amended port in table
      const updatedRow = page.locator('#tblCCL tbody tr').filter({ hasText: 'Bonifacio' }).first();
      await expect(updatedRow.locator('td:nth-child(7)')).toContainText('Port of Subic');
      await expect(updatedRow.locator('td:nth-child(10)')).toContainText(/Tentative/i);

      // Confirm unrelated records on Vessel A remain completely unchanged
      await selectVessel(page, '5'); // QA-VESSEL-A
      const santosRow = page.locator('#tblCCL tbody tr').filter({ hasText: 'Santos' }).first();
      await expect(santosRow.locator('td:nth-child(10)')).toContainText(/Next/i);
    });
  });

  // ==========================================================================
  // TEST 4: Focused CCL Regression
  // ==========================================================================
  test('TEST 4: Focused CCL Regression (Roles, Isolation, EOC, Popup Navigation)', async ({ loginAsRole, page }) => {
    // ── 1. Schedule Creation & Amendment Status ──────────────────────────────
    await test.step('Step 1: Verify schedule produces Tentative status and amendment works for authorized role', async () => {
      await loginAsRole('MANNING');
      await selectVessel(page, '6'); // QA-VESSEL-B

      const bonifacioRow = page.locator('#tblCCL tbody tr').filter({ hasText: 'Bonifacio' }).first();
      await expect(bonifacioRow.locator('td:nth-child(10)')).toContainText(/Tentative/i);
    });

    // ── 2. Unauthorized Role Restriction ────────────────────────────────────
    await test.step('Step 2: Unauthorized roles (Vessel Owner) cannot create or edit schedules', async () => {
      await loginAsRole('VESSEL_OWNER');
      await selectVessel(page, '6');

      const ownerVesselBButtons = page.locator('#tblCCL button:has-text("Schedule"), #tblCCL button:has-text("Edit"), #tblCCL button:has-text("Reliever")');
      expect(await ownerVesselBButtons.count()).toBe(0);

      await selectVessel(page, '5');
      const ownerVesselAButtons = page.locator('#tblCCL button:has-text("Schedule"), #tblCCL button:has-text("Edit"), #tblCCL button:has-text("Reliever")');
      expect(await ownerVesselAButtons.count()).toBe(0);
    });

    // ── 3. Vessel Isolation ─────────────────────────────────────────────────
    await test.step('Step 3: Vessel isolation remains strictly enforced', async () => {
      await loginAsRole('MANNING');

      // Vessel A
      await selectVessel(page, '5');
      const vesselARows = await page.locator('#tblCCL tbody tr').allInnerTexts();
      const vesselAText = vesselARows.join(' ');
      expect(vesselAText).toContain('Santos');
      expect(vesselAText).toContain('Rizal');
      expect(vesselAText).not.toContain('Bonifacio');

      // Vessel B
      await selectVessel(page, '6');
      const vesselBRows = await page.locator('#tblCCL tbody tr').allInnerTexts();
      const vesselBText = vesselBRows.join(' ');
      expect(vesselBText).toContain('Bonifacio');
      expect(vesselBText).not.toContain('Santos');
      expect(vesselBText).not.toContain('Rizal');
    });

    // ── 4. Existing EOC & Schedule Display Behavior ─────────────────────────
    await test.step('Step 4: Existing EOC and schedule status display behavior remains intact', async () => {
      await selectVessel(page, '5'); // QA-VESSEL-A

      const santosRow = page.locator('#tblCCL tbody tr').filter({ hasText: 'Santos' }).first();
      await expect(santosRow.locator('td:nth-child(10)')).toContainText(/Next/i);
      await expect(santosRow.locator('td:nth-child(11)')).toContainText(/Superseded/i);

      // EOC preview modal
      const eocBtn = santosRow.locator('button:has-text("EOC")');
      if (await eocBtn.isVisible()) {
        await eocBtn.click();
        const eocModal = page.locator('#modalEOC');
        await expect(eocModal).toBeVisible();
        await eocModal.locator('button:has-text("Close")').click();
        await expect(eocModal).toBeHidden();
      }
    });

    // ── 5. Popup Closing Returns User to Same CCL Context ───────────────────
    await test.step('Step 5: Popup closing returns user to same CCL context without page reset', async () => {
      await selectVessel(page, '6'); // QA-VESSEL-B

      const bonifacioRow = page.locator('#tblCCL tbody tr').filter({ hasText: 'Bonifacio' }).first();
      const editBtn = bonifacioRow.locator('button:has-text("Edit")');
      await editBtn.click();

      const modal = page.locator('#modalSchedule');
      await expect(modal).toBeVisible();

      // Click Cancel in modal
      const cancelBtn = modal.locator('button:has-text("Cancel")');
      await cancelBtn.click();
      await expect(modal).toBeHidden();

      // Confirm user remains on Vessel B in CCL context
      const picker = page.locator('[id$="drpVesselPicker"]');
      expect(await picker.inputValue()).toBe('6');
      await expect(bonifacioRow).toBeVisible();
    });

  });

});
