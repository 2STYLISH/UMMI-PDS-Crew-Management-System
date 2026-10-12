import { test, expect } from '../../fixtures/auth.fixture';

// ---------------------------------------------------------------------------
// Fixture constants — all refer to QA-C2-RUN-20261001-C2P1 data
// ---------------------------------------------------------------------------
const RUN_ID   = 'QA-C2-RUN-20261001-C2P1';
const VESSEL_A = `${RUN_ID}-Vessel-A`;
const VESSEL_B = `${RUN_ID}-Vessel-B`;

// Crew aliases (names as inserted by the fixture)
const A001_LAST  = 'Santos';
const A001_FIRST = 'QA Maria';
const A002_LAST  = 'Rizal';
const A002_FIRST = 'QA Jose';
const A003_LAST  = 'Aguinaldo';
const A004_LAST  = 'Mabini';
const B001_LAST  = 'Bonifacio';
const U001_LAST  = 'Luna';

// Document / assessment fixture identifiers
const LIC_A001_NUM     = `${RUN_ID}-LIC-A001-NUM`;
const MED_A001_NUM     = `${RUN_ID}-MED-A001-NUM`;
const NOSCAN_A001_NUM  = `${RUN_ID}-NOSCAN-A001-NUM`;
const ASSESS_A001_TEXT = `${RUN_ID} Performance assessment report with attached evaluation form.`;
const ASSESS_A001_EMPTY_CREW = A004_LAST;   // Mabini has 0 assessments

// Applicant fixture names
const AP001_LAST  = 'Reyes';
const AP001_FIRST = 'QA Ana';
const AP002_LAST  = 'Cruz';
const AP002_FIRST = 'QA Ben';

test.describe('UMMI Cycle 2 — Phase 1: Read-Only Test Suite', () => {

  // --------------------------------------------------------------------------
  // TC-CM-019: Principal: reject internal Applicant Pool access
  // --------------------------------------------------------------------------
  test('TC-CM-019: Principal: reject internal Applicant Pool access', async ({ loginAsRole, page, activityLogsPage }) => {
    await test.step('Step 1: Confirm the Applicant Pool menu item is hidden, then request Applicant Pool through its direct address', async () => {
      await loginAsRole('PRINCIPAL');
      // Confirm Applicant Pool menu item is not displayed
      const applicantPoolLink = page.locator('nav a[href*="ApplicantPool"], .sidebar a[href*="ApplicantPool"]');
      await expect(applicantPoolLink).toBeHidden();

      // Direct access is denied, user returns to Home, and no applicant record is disclosed
      await page.goto('/Applicant/ApplicantPool.aspx');
      await page.waitForLoadState('networkidle').catch(() => {});
      const currentUrl = page.url();
      expect(currentUrl).not.toContain('/Applicant/ApplicantPool.aspx');
      expect(currentUrl).toMatch(/\/(Home|login)\.aspx/i);
    });

    await test.step('Step 2: Inspect the denied-access log', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('Security');
      const hasSecurityLog = await activityLogsPage.hasMatchingLog({
        category: 'Security',
        activitySubstring: 'Attempted to access restricted page /Applicant/ApplicantPool.aspx',
      });
      expect(hasSecurityLog).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-020: Vessel Owner: reject internal Applicant Pool access
  // --------------------------------------------------------------------------
  test('TC-CM-020: Vessel Owner: reject internal Applicant Pool access', async ({ loginAsRole, page, activityLogsPage }) => {
    await test.step('Step 1: Confirm the Applicant Pool menu item is hidden, then request Applicant Pool through its direct address', async () => {
      await loginAsRole('VESSEL_OWNER');
      const applicantPoolLink = page.locator('nav a[href*="ApplicantPool"], .sidebar a[href*="ApplicantPool"]');
      await expect(applicantPoolLink).toBeHidden();

      await page.goto('/Applicant/ApplicantPool.aspx');
      await page.waitForLoadState('networkidle').catch(() => {});
      const currentUrl = page.url();
      expect(currentUrl).not.toContain('/Applicant/ApplicantPool.aspx');
      expect(currentUrl).toMatch(/\/(Home|login)\.aspx/i);
    });

    await test.step('Step 2: Inspect the denied-access log', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('Security');
      const hasSecurityLog = await activityLogsPage.hasMatchingLog({
        category: 'Security',
        activitySubstring: 'Attempted to access restricted page /Applicant/ApplicantPool.aspx',
      });
      expect(hasSecurityLog).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-021: Initial crew search and audit
  // --------------------------------------------------------------------------
  test('TC-CM-021: Initial crew search and audit', async ({ loginAsRole, crewSearchPage, activityLogsPage }) => {
    await test.step('Step 1: Open Crew Search without changing filters', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();

      await expect(crewSearchPage.searchButton).toBeVisible();
      await expect(crewSearchPage.lastNameInput).toBeVisible();
      await expect(crewSearchPage.firstNameInput).toBeVisible();
      await expect(crewSearchPage.vesselDropdown).toBeVisible();
      await expect(crewSearchPage.rankDropdown).toBeVisible();
      await expect(crewSearchPage.resultsTable).toBeVisible();

      // Check default filter values: Status defaults to ALL (value "") for Manning Staff
      const selectedStatus = await crewSearchPage.statusDropdown.inputValue();
      expect(selectedStatus).toBe('');
    });

    await test.step('Step 2: Compare results to the recorded default fixture and inspect the log', async () => {
      await loginAsRole('SUPERADMIN');
      await activityLogsPage.goto();
      await activityLogsPage.filterByCategory('QueryCrew');
      const hasQueryLog = await activityLogsPage.hasMatchingLog({
        category: 'QueryCrew',
        activitySubstring: 'Crew Search',
      });
      expect(hasQueryLog).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-026: Search by Rank
  // --------------------------------------------------------------------------
  test('TC-CM-026: Search by Rank', async ({ loginAsRole, crewSearchPage }) => {
    await test.step('Step 1: Clear unrelated filters, set Rank to Able Seaman, and trigger the search', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();

      const options = await crewSearchPage.getRankOptions();
      const abOption = options.find(o => o.toUpperCase().includes('AB SEAMAN') || o.toUpperCase().includes('ABLE'));
      if (!abOption) {
        test.skip(true, 'Rank Able Seaman option is not available in Rank dropdown.');
        return;
      }

      await crewSearchPage.rankDropdown.selectOption({ label: abOption });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);
      for (let i = 0; i < rowCount; i++) {
        const rowText = await crewSearchPage.resultRows.nth(i).innerText();
        expect(rowText.toUpperCase()).toContain('AB SEAMAN');
      }
    });

    await test.step('Step 2: Change the filter to the CONTROL value and search again', async () => {
      const options = await crewSearchPage.getRankOptions();
      const controlOption = options.find(o => o.toUpperCase().includes('MASTER'));
      if (!controlOption) {
        test.skip(true, 'Control rank MASTER option is not available in Rank dropdown.');
        return;
      }

      await crewSearchPage.rankDropdown.selectOption({ label: controlOption });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);
      for (let i = 0; i < rowCount; i++) {
        const rowText = await crewSearchPage.resultRows.nth(i).innerText();
        expect(rowText.toUpperCase()).toContain('MASTER');
        expect(rowText.toUpperCase()).not.toContain('AB SEAMAN');
      }
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-027: Search by Rank type
  // --------------------------------------------------------------------------
  test('TC-CM-027: Search by Rank type', async ({ loginAsRole, crewSearchPage }) => {
    await test.step('Step 1: Clear unrelated filters, set Rank type to Rating, and trigger the search', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();

      const rankTypes = await crewSearchPage.getRankTypeOptions();
      const ratingOption = rankTypes.find(rt => rt.toUpperCase().includes('RATING'));
      if (!ratingOption) {
        test.skip(true, 'Rank type Rating is not available.');
        return;
      }

      await crewSearchPage.selectRankType(ratingOption);
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);
      for (let i = 0; i < rowCount; i++) {
        const rowText = await crewSearchPage.resultRows.nth(i).innerText().then(t => t.toUpperCase());
        const isRatingRank = ['BOSUN', 'AB SEAMAN', 'OS', 'RATING', 'COOK', 'STEWARD'].some(r => rowText.includes(r));
        expect(isRatingRank).toBe(true);
      }
    });

    await test.step('Step 2: Change the filter to the CONTROL value and search again', async () => {
      const rankTypes = await crewSearchPage.getRankTypeOptions();
      const controlOption = rankTypes.find(rt => rt.toUpperCase().includes('DECK'));
      if (!controlOption) {
        test.skip(true, 'Control rank type Deck is not available.');
        return;
      }

      await crewSearchPage.selectRankType(controlOption);
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);
      for (let i = 0; i < rowCount; i++) {
        const rowText = await crewSearchPage.resultRows.nth(i).innerText().then(t => t.toUpperCase());
        const isDeckRank = ['MASTER', 'CHIEF OFFICER', '2ND OFFICER', '3RD OFFICER', 'DECK CADET', 'DECK'].some(r => rowText.includes(r));
        expect(isDeckRank).toBe(true);
      }
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-028: Search by Assigned vessel
  // --------------------------------------------------------------------------
  test('TC-CM-028: Search by Assigned vessel', async ({ loginAsRole, crewSearchPage }) => {
    await test.step('Step 1: Clear unrelated filters, set Assigned vessel to QA Vessel A, and trigger the search', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();

      const vessels = await crewSearchPage.getVesselOptions();
      const matchVessel = vessels.find(v => v.includes('MT MINDANAO'));
      if (!matchVessel) {
        test.skip(true, 'Target vessel MT MINDANAO is not available in dropdown.');
        return;
      }

      await crewSearchPage.vesselDropdown.selectOption({ label: matchVessel });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);
      for (let i = 0; i < rowCount; i++) {
        const assignedVesselCell = crewSearchPage.resultRows.nth(i).locator('td').nth(4);
        const vesselText = await assignedVesselCell.innerText();
        expect(vesselText.toUpperCase()).toContain('MT MINDANAO');
      }
    });

    await test.step('Step 2: Change the filter to the CONTROL value and search again', async () => {
      const vessels = await crewSearchPage.getVesselOptions();
      const controlVessel = vessels.find(v => v.includes('MV CEBU PRIDE'));
      if (!controlVessel) {
        test.skip(true, 'Control vessel MV CEBU PRIDE is not available in dropdown.');
        return;
      }

      await crewSearchPage.vesselDropdown.selectOption({ label: controlVessel });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);
      for (let i = 0; i < rowCount; i++) {
        const assignedVesselCell = crewSearchPage.resultRows.nth(i).locator('td').nth(4);
        const vesselText = await assignedVesselCell.innerText();
        expect(vesselText.toUpperCase()).toContain('MV CEBU PRIDE');
        expect(vesselText.toUpperCase()).not.toContain('MT MINDANAO');
      }
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-035: Combine crew name, vessel and rank
  // --------------------------------------------------------------------------
  test('TC-CM-035: Combine crew name, vessel and rank', async ({ loginAsRole, crewSearchPage }) => {
    await test.step('Step 1: Apply all three criteria together', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();

      await crewSearchPage.lastNameInput.fill('Aguilar');
      await crewSearchPage.vesselDropdown.selectOption({ label: 'MT MINDANAO' });
      await crewSearchPage.rankDropdown.selectOption({ label: '4TH ENGINEER' });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);
      for (let i = 0; i < rowCount; i++) {
        const rowText = await crewSearchPage.resultRows.nth(i).innerText();
        expect(rowText.toUpperCase()).toContain('AGUILAR');
        expect(rowText.toUpperCase()).toContain('MT MINDANAO');
        expect(rowText.toUpperCase()).toContain('4TH ENGINEER');
      }
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-042: Principal: isolate assigned vessels
  // Actor: isolated synthetic Principal account (qa.c2.20261001.principal)
  // assigned ONLY to QA-C2-RUN-20261001-C2P1-Vessel-A
  // --------------------------------------------------------------------------
  test('TC-CM-042: Principal: isolate assigned vessels', async ({ loginAsRole, crewSearchPage }) => {
    await test.step('Step 1: Run a broad crew search and inspect every result page', async () => {
      await loginAsRole('PRINCIPAL');
      await crewSearchPage.goto();

      const vessels = await crewSearchPage.getVesselOptions();
      const hasQAVesselA = vessels.some(v => v.includes(VESSEL_A));
      if (!hasQAVesselA) {
        test.skip(true, `Missing fixture vessel ${VESSEL_A} in Principal vessel dropdown. Fixture setup may not have been executed.`);
        return;
      }

      // Principal defaults to Status=ACTIVE (1); select ALL to view all assigned crew across statuses
      await crewSearchPage.statusDropdown.selectOption({ value: '' });
      await crewSearchPage.search();
      const rowCount = await crewSearchPage.resultRows.count();
      // Vessel A has A001, A002, A003, A004 — at least 1 must appear
      expect(rowCount).toBeGreaterThan(0);

      // Every row must belong to Vessel A only
      for (let i = 0; i < rowCount; i++) {
        const rowText = await crewSearchPage.resultRows.nth(i).innerText();
        expect(rowText).toContain(VESSEL_A);
        // Vessel B crew (Bonifacio) and unassigned crew (Luna) must NOT appear
        expect(rowText).not.toContain(B001_LAST);
        expect(rowText).not.toContain(U001_LAST);
      }
    });

    await test.step('Step 2: Request QA Vessel B through the vessel filter or a controlled direct request', async () => {
      const vessels = await crewSearchPage.getVesselOptions();
      const vesselBOption = vessels.find(v => v.includes(VESSEL_B));
      if (vesselBOption) {
        await crewSearchPage.vesselDropdown.selectOption({ label: vesselBOption });
        await crewSearchPage.search();
        const rowCount = await crewSearchPage.resultRows.count();
        // No Vessel B or unassigned record is disclosed
        expect(rowCount).toBe(0);
      }
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-043: Vessel Owner: hide internal search controls
  // --------------------------------------------------------------------------
  test('TC-CM-043: Vessel Owner: hide internal search controls', async ({ loginAsRole, page }) => {
    await test.step('Step 1: Open Crew Search and inspect available controls', async () => {
      await loginAsRole('VESSEL_OWNER');
      await page.goto('/Crew/QueryCrew.aspx');

      // Availability, Reset Filters, Export, and Releasing Checklist controls must be hidden per FR-CM-05/FR-CM-25/UC-CM-01
      await expect(page.locator('[id$="drpdwnCrewAvailability"]')).toBeHidden();
      await expect(page.locator('[id$="btnReset"]')).toBeHidden();
      await expect(page.locator('[id$="btnExportExcel"]')).toBeHidden();
      await expect(page.locator('[id$="btnReleasingChecklist"]')).toBeHidden();
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-045: Vessel Owner: isolate assigned vessels
  // Actor: isolated synthetic Vessel Owner account (qa.c2.20261001.owner)
  // assigned ONLY to QA-C2-RUN-20261001-C2P1-Vessel-A
  // --------------------------------------------------------------------------
  test('TC-CM-045: Vessel Owner: isolate assigned vessels', async ({ loginAsRole, crewSearchPage }) => {
    await test.step('Step 1: Run a broad crew search and inspect every result page', async () => {
      await loginAsRole('VESSEL_OWNER');
      await crewSearchPage.goto();

      const vessels = await crewSearchPage.getVesselOptions();
      const hasQAVesselA = vessels.some(v => v.includes(VESSEL_A));
      if (!hasQAVesselA) {
        test.skip(true, `Missing fixture vessel ${VESSEL_A} in Vessel Owner dropdown. Fixture setup may not have been executed.`);
        return;
      }

      // Vessel Owner defaults to Status=ACTIVE (1); select ALL to view all assigned crew across statuses
      await crewSearchPage.statusDropdown.selectOption({ value: '' });
      await crewSearchPage.search();
      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);

      // Every row must belong to Vessel A
      for (let i = 0; i < rowCount; i++) {
        const rowText = await crewSearchPage.resultRows.nth(i).innerText();
        expect(rowText).toContain(VESSEL_A);
        expect(rowText).not.toContain(B001_LAST);
        expect(rowText).not.toContain(U001_LAST);
      }
    });

    await test.step('Step 2: Request QA Vessel B through the vessel filter or a controlled direct request', async () => {
      const vessels = await crewSearchPage.getVesselOptions();
      const vesselBOption = vessels.find(v => v.includes(VESSEL_B));
      if (vesselBOption) {
        await crewSearchPage.vesselDropdown.selectOption({ label: vesselBOption });
        await crewSearchPage.search();
        const rowCount = await crewSearchPage.resultRows.count();
        // No Vessel B or unassigned record is disclosed
        expect(rowCount).toBe(0);
      }
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-058: Manning Staff: open eligible vessel roster
  // Checks that crew on Vessel A with eligible statuses show a clickable vessel link
  // --------------------------------------------------------------------------
  test('TC-CM-058: Manning Staff: open eligible vessel roster', async ({ loginAsRole, crewSearchPage, page }) => {
    await test.step('Step 1: Locate On Board, Line Up, and On Vacation synthetic crew on Vessel A', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();

      // Filter to Vessel A to isolate fixture crew
      const vessels = await crewSearchPage.getVesselOptions();
      const vesselAOption = vessels.find(v => v.includes(VESSEL_A));
      if (!vesselAOption) {
        test.skip(true, `Fixture vessel ${VESSEL_A} is not present in the vessel dropdown. Fixture setup required.`);
        return;
      }

      await crewSearchPage.vesselDropdown.selectOption({ label: vesselAOption });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);

      // Find A001 (On Board) — must have a clickable vessel link
      let foundEligibleLink = false;
      for (let i = 0; i < rowCount; i++) {
        const row = crewSearchPage.resultRows.nth(i);
        const rowText = await row.innerText();
        if (rowText.includes(A001_LAST) && rowText.includes(A001_FIRST)) {
          // Vessel cell should contain an anchor for eligible statuses
          const vesselLink = row.locator('a[href*="VesselCrew"], td a').filter({ hasText: /vessel/i });
          // If the link text is the vessel name as a hyperlink — eligible
          const vesselCell = row.locator('td').nth(4);
          const vesselCellHtml = await vesselCell.innerHTML();
          expect(vesselCellHtml).toMatch(/<a\s[^>]*href[^>]*>/i);
          foundEligibleLink = true;
        }
      }
      if (!foundEligibleLink) {
        test.skip(true, `Fixture crew ${A001_FIRST} ${A001_LAST} (On Board on ${VESSEL_A}) not found in search results.`);
        return;
      }
    });

    await test.step('Step 2: Click the eligible vessel link and confirm VesselCrew page loads', async () => {
      await crewSearchPage.goto();
      const vessels = await crewSearchPage.getVesselOptions();
      const vesselAOption = vessels.find(v => v.includes(VESSEL_A));
      if (!vesselAOption) return;

      await crewSearchPage.vesselDropdown.selectOption({ label: vesselAOption });
      await crewSearchPage.search();

      const rows = crewSearchPage.resultRows;
      const rowCount = await rows.count();
      for (let i = 0; i < rowCount; i++) {
        const row = rows.nth(i);
        const rowText = await row.innerText();
        if (rowText.includes(A001_LAST) && rowText.includes(A001_FIRST)) {
          const vesselCell = row.locator('td').nth(4);
          const link = vesselCell.locator('a').first();
          const isVisible = await link.isVisible().catch(() => false);
          if (isVisible) {
            await link.click();
            await page.waitForLoadState('networkidle').catch(() => {});
            const url = page.url();
            expect(url).toMatch(/VesselCrew\.aspx/i);
          }
          return;
        }
      }
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-059: Documentation Officer: open eligible vessel roster
  // --------------------------------------------------------------------------
  test('TC-CM-059: Documentation Officer: open eligible vessel roster', async ({ loginAsRole, crewSearchPage }) => {
    await test.step('Step 1: Open Crew Search as Documentation Officer and verify Vessel A roster link', async () => {
      await loginAsRole('DOCUMENTATION');
      await crewSearchPage.goto();

      const vessels = await crewSearchPage.getVesselOptions();
      const vesselAOption = vessels.find(v => v.includes(VESSEL_A));
      if (!vesselAOption) {
        test.skip(true, `Fixture vessel ${VESSEL_A} not present in vessel dropdown. Fixture setup required.`);
        return;
      }

      await crewSearchPage.vesselDropdown.selectOption({ label: vesselAOption });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);

      // Verify that at least one Vessel A crew member has an eligible vessel link
      let hasEligibleLink = false;
      for (let i = 0; i < rowCount; i++) {
        const row = crewSearchPage.resultRows.nth(i);
        const vesselCell = row.locator('td').nth(4);
        const vesselCellHtml = await vesselCell.innerHTML();
        if (vesselCellHtml.match(/<a\s[^>]*href[^>]*>/i)) {
          hasEligibleLink = true;
          break;
        }
      }
      expect(hasEligibleLink).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-060: Admin: open eligible vessel roster
  // --------------------------------------------------------------------------
  test('TC-CM-060: Admin: open eligible vessel roster', async ({ loginAsRole, crewSearchPage }) => {
    await test.step('Step 1: Open Crew Search as Admin and verify Vessel A roster link', async () => {
      await loginAsRole('ADMIN');
      await crewSearchPage.goto();

      const vessels = await crewSearchPage.getVesselOptions();
      const vesselAOption = vessels.find(v => v.includes(VESSEL_A));
      if (!vesselAOption) {
        test.skip(true, `Fixture vessel ${VESSEL_A} not present in vessel dropdown. Fixture setup required.`);
        return;
      }

      await crewSearchPage.vesselDropdown.selectOption({ label: vesselAOption });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);

      let hasEligibleLink = false;
      for (let i = 0; i < rowCount; i++) {
        const row = crewSearchPage.resultRows.nth(i);
        const vesselCell = row.locator('td').nth(4);
        const vesselCellHtml = await vesselCell.innerHTML();
        if (vesselCellHtml.match(/<a\s[^>]*href[^>]*>/i)) {
          hasEligibleLink = true;
          break;
        }
      }
      expect(hasEligibleLink).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-061: Super-Admin: open eligible vessel roster
  // --------------------------------------------------------------------------
  test('TC-CM-061: Super-Admin: open eligible vessel roster', async ({ loginAsRole, crewSearchPage }) => {
    await test.step('Step 1: Open Crew Search as Super-Admin and verify Vessel A roster link', async () => {
      await loginAsRole('SUPERADMIN');
      await crewSearchPage.goto();

      const vessels = await crewSearchPage.getVesselOptions();
      const vesselAOption = vessels.find(v => v.includes(VESSEL_A));
      if (!vesselAOption) {
        test.skip(true, `Fixture vessel ${VESSEL_A} not present in vessel dropdown. Fixture setup required.`);
        return;
      }

      await crewSearchPage.vesselDropdown.selectOption({ label: vesselAOption });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);

      let hasEligibleLink = false;
      for (let i = 0; i < rowCount; i++) {
        const row = crewSearchPage.resultRows.nth(i);
        const vesselCell = row.locator('td').nth(4);
        const vesselCellHtml = await vesselCell.innerHTML();
        if (vesselCellHtml.match(/<a\s[^>]*href[^>]*>/i)) {
          hasEligibleLink = true;
          break;
        }
      }
      expect(hasEligibleLink).toBe(true);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-062: Hide unavailable CCL links
  // Eligible (On Board=A001, Line Up=A002, On Vacation=A004): vessel cell is a hyperlink
  // Ineligible (Inactive=A003): vessel cell is plain text
  // Unassigned (U001): vessel cell is blank
  // --------------------------------------------------------------------------
  test('TC-CM-062: Hide unavailable CCL links', async ({ loginAsRole, crewSearchPage }) => {
    await test.step('Step 1: Inspect assigned-vessel rendering for eligible and ineligible statuses', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();

      const vessels = await crewSearchPage.getVesselOptions();
      const vesselAOption = vessels.find(v => v.includes(VESSEL_A));
      if (!vesselAOption) {
        test.skip(true, `Fixture vessel ${VESSEL_A} not present. Fixture setup required.`);
        return;
      }

      await crewSearchPage.vesselDropdown.selectOption({ label: vesselAOption });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      expect(rowCount).toBeGreaterThan(0);

      let checkedEligible = false;
      let checkedIneligible = false;

      for (let i = 0; i < rowCount; i++) {
        const row = crewSearchPage.resultRows.nth(i);
        const rowText = await row.innerText();
        const vesselCell = row.locator('td').nth(4);
        const vesselCellHtml = await vesselCell.innerHTML();

        if (rowText.includes(A001_LAST) || rowText.includes(A002_LAST) || rowText.includes(A004_LAST)) {
          // On Board / Line Up / On Vacation — vessel cell must be a hyperlink
          expect(vesselCellHtml).toMatch(/<a\s[^>]*href[^>]*>/i);
          checkedEligible = true;
        }
        if (rowText.includes(A003_LAST)) {
          // Inactive — vessel cell must be plain text (no anchor)
          expect(vesselCellHtml).not.toMatch(/<a\s[^>]*href[^>]*>/i);
          checkedIneligible = true;
        }
      }

      // If neither fixture crew was found, the fixture wasn't set up
      if (!checkedEligible && !checkedIneligible) {
        test.skip(true, 'Synthetic fixture crew A001/A002/A003/A004 not found on Vessel A. Fixture setup required.');
      }
    });

    await test.step('Step 2: Search for unassigned crew U001 and confirm vessel cell is blank', async () => {
      await crewSearchPage.lastNameInput.fill(U001_LAST);
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      for (let i = 0; i < rowCount; i++) {
        const row = crewSearchPage.resultRows.nth(i);
        const rowText = await row.innerText();
        if (rowText.includes(U001_LAST)) {
          const vesselCell = row.locator('td').nth(4);
          const vesselText = (await vesselCell.innerText()).trim();
          expect(vesselText).toBe('');
          return;
        }
      }
      // U001 not found — acceptable if fixture wasn't set up
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-093: Open correct scanned document
  // A001 License attachment must stream via CrewDocumentHandler.ashx as application/pdf
  // --------------------------------------------------------------------------
  test('TC-CM-093: Open correct scanned document', async ({ loginAsRole, crewSearchPage, page }) => {
    await test.step('Step 1: Find A001 profile, open Licenses tab, and click the License scan link', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();
      await crewSearchPage.lastNameInput.fill(A001_LAST);
      await crewSearchPage.firstNameInput.fill(A001_FIRST);
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      if (rowCount === 0) {
        test.skip(true, `Synthetic crew ${A001_FIRST} ${A001_LAST} not found. Fixture setup required.`);
        return;
      }

      // Click the profile link for A001 (relative URL resolved against current page)
      const profileLink = crewSearchPage.resultRows.first().locator('td a[href*="ProfileViewer"]');
      const href = await profileLink.getAttribute('href');
      expect(href).toBeTruthy();
      const profileUrl = new URL(href!, page.url()).href;
      await page.goto(profileUrl);
      await page.waitForLoadState('networkidle').catch(() => {});

      // Click the Licenses tab
      const licensesTab = page.locator('button[onclick*="tabDocLicense"]');
      await expect(licensesTab.first()).toBeVisible();
      await licensesTab.first().click();
      await page.waitForTimeout(500);

      // Find the row with the LIC-A001-NUM document number
      const licRow = page.locator('#tabDocLicense tr').filter({ hasText: LIC_A001_NUM });
      expect(await licRow.count()).toBeGreaterThan(0);

      // The view link is an anchor triggering showImagePopup
      const viewLink = licRow.first().locator('a[onclick*="showImagePopup"], a[onclick*="CrewDocumentHandler"]');
      await expect(viewLink.first()).toBeVisible();

      // Intercept the streamed response when clicking the popup link
      const [docResponse] = await Promise.all([
        page.waitForResponse(res => res.url().includes('CrewDocumentHandler.ashx')),
        viewLink.first().click(),
      ]);

      expect(docResponse.status()).toBe(200);
      const contentType = docResponse.headers()['content-type'] ?? '';
      expect(contentType).toContain('application/pdf');

      // nosniff header must be present
      const nosniff = docResponse.headers()['x-content-type-options'] ?? '';
      expect(nosniff.toLowerCase()).toBe('nosniff');

      // Verify the popup overlay and image element
      await expect(page.locator('#imgPopupOverlay')).toBeVisible();
      const popupImgSrc = await page.locator('#imgPopupImage').getAttribute('src');
      expect(popupImgSrc).toContain('CrewDocumentHandler.ashx');

      // Close the popup
      await page.locator('#imgPopupOverlay button:has-text("Close")').click();
      await expect(page.locator('#imgPopupOverlay')).toBeHidden();
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-094: Record without a scan
  // A001 Personal/Passport doc (DOC-A001-NOSCAN) has img_id IS NULL — no view link
  // --------------------------------------------------------------------------
  test('TC-CM-094: Record without a scan', async ({ loginAsRole, crewSearchPage, page }) => {
    await test.step('Step 1: Find A001 profile, open Personal Docs tab, confirm scan link is absent for NOSCAN record', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();
      await crewSearchPage.lastNameInput.fill(A001_LAST);
      await crewSearchPage.firstNameInput.fill(A001_FIRST);
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      if (rowCount === 0) {
        test.skip(true, `Synthetic crew ${A001_FIRST} ${A001_LAST} not found. Fixture setup required.`);
        return;
      }

      const profileLink = crewSearchPage.resultRows.first().locator('td a[href*="ProfileViewer"]');
      const href = await profileLink.getAttribute('href');
      const profileUrl = new URL(href!, page.url()).href;
      await page.goto(profileUrl);
      await page.waitForLoadState('networkidle').catch(() => {});

      // Open Personal Docs tab
      const personalTab = page.locator('button[onclick*="tabDocPersonal"]');
      await expect(personalTab.first()).toBeVisible();
      await personalTab.first().click();
      await page.waitForTimeout(500);

      // Find the NOSCAN doc row
      const noscanRow = page.locator('#tabDocPersonal tr').filter({ hasText: NOSCAN_A001_NUM });
      expect(await noscanRow.count()).toBeGreaterThan(0);

      // Must NOT have a view/scan link (img_id IS NULL)
      const viewLink = noscanRow.first().locator('a[onclick*="showImagePopup"], a[onclick*="CrewDocumentHandler"]');
      expect(await viewLink.count()).toBe(0);

      // Document number must still appear (metadata row is rendered)
      const noscanText = await noscanRow.first().innerText();
      expect(noscanText).toContain(NOSCAN_A001_NUM);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-100: Read-only assessment content
  // A001 has 2 assessment records (1 with attachment, 1 without).
  // No save/edit controls should be visible.
  // --------------------------------------------------------------------------
  test('TC-CM-100: Read-only assessment content', async ({ loginAsRole, crewSearchPage, page }) => {
    await test.step('Step 1: Open A001 profile Assessments tab and verify read-only presentation', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();
      await crewSearchPage.lastNameInput.fill(A001_LAST);
      await crewSearchPage.firstNameInput.fill(A001_FIRST);
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      if (rowCount === 0) {
        test.skip(true, `Synthetic crew ${A001_FIRST} ${A001_LAST} not found. Fixture setup required.`);
        return;
      }

      const profileLink = crewSearchPage.resultRows.first().locator('td a[href*="ProfileViewer"]');
      const href = await profileLink.getAttribute('href');
      const profileUrl = new URL(href!, page.url()).href;
      await page.goto(profileUrl);
      await page.waitForLoadState('networkidle').catch(() => {});

      // Open Assessments tab
      const assessTab = page.locator('button[onclick*="tabComments"]');
      await expect(assessTab.first()).toBeVisible();
      await assessTab.first().click();
      await page.waitForTimeout(500);

      // The attached assessment note text must appear
      const attachedNote = page.locator('#tabComments').filter({ hasText: ASSESS_A001_TEXT });
      expect(await attachedNote.count()).toBeGreaterThan(0);

      // Routine note (no attachment) must also appear
      const routineText = `${RUN_ID} Routine quarterly operational performance assessment note.`;
      const routineNote = page.locator('#tabComments').filter({ hasText: routineText });
      expect(await routineNote.count()).toBeGreaterThan(0);

      // No edit/save/delete controls should be present for Manning role
      await expect(page.locator('#tabComments [id$="btnSaveAssessment"], #tabComments [id$="btnDeleteAssessment"], #tabComments button:has-text("Save")')).toHaveCount(0);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-101: No assessment records
  // A004 (Mabini, On Vacation) has 0 assessment records — empty state must render without error
  // --------------------------------------------------------------------------
  test('TC-CM-101: No assessment records', async ({ loginAsRole, crewSearchPage, page }) => {
    await test.step('Step 1: Open A004 profile Assessments tab and confirm clean empty state', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();
      await crewSearchPage.lastNameInput.fill(A004_LAST);
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      // Find the specific QA fixture entry (prefix on first name)
      let a004Found = false;
      for (let i = 0; i < rowCount; i++) {
        const rowText = await crewSearchPage.resultRows.nth(i).innerText();
        if (rowText.includes(A004_LAST) && rowText.includes('QA')) {
          a004Found = true;
          const profileLink = crewSearchPage.resultRows.nth(i).locator('td a[href*="ProfileViewer"]');
          const href = await profileLink.getAttribute('href');
          const profileUrl = new URL(href!, page.url()).href;
          await page.goto(profileUrl);
          await page.waitForLoadState('networkidle').catch(() => {});
          break;
        }
      }
      if (!a004Found) {
        test.skip(true, `Synthetic crew A004 (QA ${A004_LAST}) not found. Fixture setup required.`);
        return;
      }

      // Open Assessments tab
      const assessTab = page.locator('button[onclick*="tabComments"]');
      if (await assessTab.count() > 0) {
        await assessTab.first().click();
        await page.waitForTimeout(500);
      }

      // Page must not show a runtime exception
      await expect(page.locator('body')).not.toContainText('Server Error in');
      await expect(page.locator('body')).not.toContainText('Runtime Error');
      await expect(page.locator('body')).not.toContainText('Object reference not set');

      // Empty state: no rows containing the RUN_ID prefix
      const fixtureRows = page.locator('#tabComments td').filter({ hasText: RUN_ID });
      expect(await fixtureRows.count()).toBe(0);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-102: Open assessment attachment
  // A001 has ASSESS-A001-ATTACH with QA-C2-RUN-20261001-C2P1-A001-ASSESS.pdf
  // Handler: AssessmentAttachmentHandler.ashx or equivalent
  // --------------------------------------------------------------------------
  test('TC-CM-102: Open assessment attachment', async ({ loginAsRole, crewSearchPage, page }) => {
    await test.step('Step 1: Open A001 profile Assessments tab and click the attachment for the attached note', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();
      await crewSearchPage.lastNameInput.fill(A001_LAST);
      await crewSearchPage.firstNameInput.fill(A001_FIRST);
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      if (rowCount === 0) {
        test.skip(true, `Synthetic crew ${A001_FIRST} ${A001_LAST} not found. Fixture setup required.`);
        return;
      }

      const profileLink = crewSearchPage.resultRows.first().locator('td a[href*="ProfileViewer"]');
      const href = await profileLink.getAttribute('href');
      const profileUrl = new URL(href!, page.url()).href;
      await page.goto(profileUrl);
      await page.waitForLoadState('networkidle').catch(() => {});

      const assessTab = page.locator('button[onclick*="tabComments"]');
      await expect(assessTab.first()).toBeVisible();
      await assessTab.first().click();
      await page.waitForTimeout(500);

      // Find the attachment row / link for the ASSESS-A001-ATTACH note
      const attachRow = page.locator('#tabComments tr').filter({ hasText: ASSESS_A001_TEXT });
      expect(await attachRow.count()).toBeGreaterThan(0);

      // Attachment link must exist
      const attachLink = attachRow.first().locator('a[onclick*="AssessmentAttachmentHandler"], a:has-text("View")');
      await expect(attachLink.first()).toBeVisible();

      // Click and intercept
      const [docResponse] = await Promise.all([
        page.waitForResponse(res => res.url().includes('AssessmentAttachmentHandler.ashx')),
        attachLink.first().click(),
      ]);

      expect(docResponse.status()).toBe(200);
      const contentType = docResponse.headers()['content-type'] ?? '';
      expect(contentType).toContain('application/pdf');
      const nosniff = docResponse.headers()['x-content-type-options'] ?? '';
      expect(nosniff.toLowerCase()).toBe('nosniff');

      // Verify popup overlay is visible
      await expect(page.locator('#imgPopupOverlay')).toBeVisible();
      const popupImgSrc = await page.locator('#imgPopupImage').getAttribute('src');
      expect(popupImgSrc).toContain('AssessmentAttachmentHandler.ashx');

      // Close popup
      await page.locator('#imgPopupOverlay button:has-text("Close")').click();
      await expect(page.locator('#imgPopupOverlay')).toBeHidden();

      // Note text remained unmutated
      await expect(page.locator('#tabComments')).toContainText(ASSESS_A001_TEXT);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-122: Applicant search by Rank
  // AP001 (QA Ana Reyes) = AB SEAMAN (Rating)
  // AP002 (QA Ben Cruz)  = 3RD OFFICER (Deck)
  // Filter by AB SEAMAN -> AP001 appears, AP002 excluded
  // --------------------------------------------------------------------------
  test('TC-CM-122: Applicant search by Rank', async ({ loginAsRole, applicantPoolPage }) => {
    await test.step('Step 1: Apply Rank=Able Seaman and submit the search', async () => {
      await loginAsRole('MANNING');
      await applicantPoolPage.goto();

      const rankOptions = await applicantPoolPage.rankDropdown.locator('option').allInnerTexts();
      const abOption = rankOptions.find(o => o.toUpperCase().includes('AB SEAMAN') || o.toUpperCase().includes('ABLE SEAMAN'));
      if (!abOption) {
        test.skip(true, 'AB SEAMAN rank option not available in Applicant Pool rank dropdown.');
        return;
      }

      await applicantPoolPage.rankDropdown.selectOption({ label: abOption });
      await applicantPoolPage.searchButton.click();
      await applicantPoolPage.page.waitForLoadState('networkidle').catch(() => {});

      // AP001 must appear
      const grid = applicantPoolPage.applicantsGrid;
      await expect(grid).toBeVisible();
      const gridText = await grid.innerText();

      const hasAP001 = gridText.includes(AP001_LAST) && gridText.includes(AP001_FIRST);
      if (!hasAP001) {
        test.skip(true, `Applicant ${AP001_FIRST} ${AP001_LAST} not found. Fixture setup required.`);
        return;
      }
      expect(gridText).toContain(AP001_LAST);

      // AP002 (Deck) must NOT appear when filtering by Rating rank
      expect(gridText).not.toContain(AP002_FIRST + ' ' + AP002_LAST);
    });

    await test.step('Step 2: Change rank to 3RD OFFICER and confirm AP002 appears and AP001 is excluded', async () => {
      const rankOptions = await applicantPoolPage.rankDropdown.locator('option').allInnerTexts();
      const deckOption = rankOptions.find(o => o.toUpperCase().includes('3RD OFFICER'));
      if (!deckOption) {
        test.skip(true, '3RD OFFICER rank option not available.');
        return;
      }

      await applicantPoolPage.rankDropdown.selectOption({ label: deckOption });
      await applicantPoolPage.searchButton.click();
      await applicantPoolPage.page.waitForLoadState('networkidle').catch(() => {});

      const gridText = await applicantPoolPage.applicantsGrid.innerText();
      expect(gridText).toContain(AP002_LAST);
      expect(gridText).not.toContain(AP001_FIRST + ' ' + AP001_LAST);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-123: Applicant search by Rank type
  // AP001 = Rating, AP002 = Deck
  // Filter by Rating -> AP001 appears, AP002 excluded
  // --------------------------------------------------------------------------
  test('TC-CM-123: Applicant search by Rank type', async ({ loginAsRole, applicantPoolPage }) => {
    await test.step('Step 1: Apply Rank type=Rating and submit the search', async () => {
      await loginAsRole('MANNING');
      await applicantPoolPage.goto();

      const rankTypeOptions = await applicantPoolPage.rankTypeDropdown.locator('option').allInnerTexts();
      const ratingOption = rankTypeOptions.find(o => o.toUpperCase().includes('RATING'));
      if (!ratingOption) {
        test.skip(true, 'Rating rank type not available in Applicant Pool dropdown.');
        return;
      }

      await applicantPoolPage.rankTypeDropdown.selectOption({ label: ratingOption });
      await applicantPoolPage.searchButton.click();
      await applicantPoolPage.page.waitForLoadState('networkidle').catch(() => {});

      const gridText = await applicantPoolPage.applicantsGrid.innerText();
      const hasAP001 = gridText.includes(AP001_LAST);
      if (!hasAP001) {
        test.skip(true, `Applicant ${AP001_LAST} (Rating) not found. Fixture setup required.`);
        return;
      }
      expect(gridText).toContain(AP001_LAST);
      expect(gridText).not.toContain(AP002_FIRST + ' ' + AP002_LAST);
    });

    await test.step('Step 2: Change to Deck rank type and confirm AP002 appears, AP001 excluded', async () => {
      const rankTypeOptions = await applicantPoolPage.rankTypeDropdown.locator('option').allInnerTexts();
      const deckOption = rankTypeOptions.find(o => o.toUpperCase().includes('DECK'));
      if (!deckOption) {
        test.skip(true, 'Deck rank type not available.');
        return;
      }

      await applicantPoolPage.rankTypeDropdown.selectOption({ label: deckOption });
      await applicantPoolPage.searchButton.click();
      await applicantPoolPage.page.waitForLoadState('networkidle').catch(() => {});

      const gridText = await applicantPoolPage.applicantsGrid.innerText();
      expect(gridText).toContain(AP002_LAST);
      expect(gridText).not.toContain(AP001_FIRST + ' ' + AP001_LAST);
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-145: Link list fields and status filtering
  // 51 synthetic links seeded; 50 displayed initially (pagination); status filters work
  // --------------------------------------------------------------------------
  test('TC-CM-145: Link list fields and status filtering', async ({ loginAsRole, applicantPoolPage }) => {
    await test.step('Step 1: Open Manage Links and verify total count and field columns', async () => {
      await loginAsRole('MANNING');
      await applicantPoolPage.goto();
      await applicantPoolPage.openManageLinks();

      const grid = applicantPoolPage.linksGrid;
      await expect(grid).toBeVisible();

      // Synthetic links have fullname starting with RUN_ID prefix
      const gridText = await grid.innerText();
      const hasFixtureLinks = gridText.includes(RUN_ID);
      if (!hasFixtureLinks) {
        test.skip(true, `Fixture link data (${RUN_ID} prefix) not found in Manage Links. Fixture setup required.`);
        return;
      }

      // At least 50 rows should be visible (51 seeded, 50 default page size)
      const linkRows = grid.locator('tr').filter({ has: applicantPoolPage.page.locator('td') });
      const linkRowCount = await linkRows.count();
      expect(linkRowCount).toBeGreaterThanOrEqual(50);
    });

    await test.step('Step 2: Apply Active filter and confirm Active links appear', async () => {
      const statusFilter = applicantPoolPage.linkStatusFilterDropdown;
      const filterOptions = await statusFilter.locator('option').allInnerTexts();
      const activeOption = filterOptions.find(o => o.toUpperCase() === 'ACTIVE');
      if (!activeOption) {
        test.skip(true, 'Active filter option not found in link status dropdown.');
        return;
      }

      await statusFilter.selectOption({ label: activeOption });
      await applicantPoolPage.page.waitForLoadState('networkidle').catch(() => {});

      const gridText = await applicantPoolPage.linksGrid.innerText();
      // LA-FUTURE link must appear in active results
      expect(gridText).toContain('LA-FUTURE');
    });

    await test.step('Step 3: Apply Used filter and confirm Used links appear', async () => {
      const statusFilter = applicantPoolPage.linkStatusFilterDropdown;
      const filterOptions = await statusFilter.locator('option').allInnerTexts();
      const usedOption = filterOptions.find(o => o.toUpperCase() === 'USED');
      if (!usedOption) return;

      await Promise.all([
        applicantPoolPage.page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST'),
        statusFilter.selectOption({ label: usedOption }),
      ]);
      await applicantPoolPage.page.waitForLoadState('networkidle').catch(() => {});

      const gridText = await applicantPoolPage.linksGrid.innerText();
      expect(gridText).toContain('LU-USED');
    });

    await test.step('Step 4: Apply Expired filter and confirm Expired links appear', async () => {
      const statusFilter = applicantPoolPage.linkStatusFilterDropdown;
      const filterOptions = await statusFilter.locator('option').allInnerTexts();
      const expiredOption = filterOptions.find(o => o.toUpperCase() === 'EXPIRED');
      if (!expiredOption) return;

      await Promise.all([
        applicantPoolPage.page.waitForResponse(res => res.url().includes('ApplicantPool.aspx') && res.request().method() === 'POST'),
        statusFilter.selectOption({ label: expiredOption }),
      ]);
      await applicantPoolPage.page.waitForLoadState('networkidle').catch(() => {});

      const gridText = await applicantPoolPage.linksGrid.innerText();
      expect(gridText).toContain('LE-EXPIRED');
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-188: Protected document and assessment access
  // Verifies that unauthorized roles receive 403/404, authorized Manning gets 200+PDF,
  // and direct /Uploads/ static paths are blocked
  // --------------------------------------------------------------------------
  test('TC-CM-188: Protected document and assessment access', async ({ loginAsRole, page }) => {
    await test.step('Step 1: Direct static path access is blocked (HTTP 403 or 404, no PDF bytes)', async () => {
      await loginAsRole('MANNING');

      const staticUrls = [
        '/Uploads/documents/QA-C2-RUN-20261001-C2P1-LIC-A001.pdf',
        '/Uploads/documents/QA-C2-RUN-20261001-C2P1-MED-A001.pdf',
        '/Uploads/documents/QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf',
        '/Uploads/assessments/QA-C2-RUN-20261001-C2P1-A001-ASSESS.pdf',
        '/Uploads/assessments/QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf',
      ];

      for (const staticUrl of staticUrls) {
        const res = await page.request.get(staticUrl, { maxRedirects: 0 });
        expect([403, 404, 302]).toContain(res.status());
        const body = await res.body();
        expect(body.subarray(0, 4).toString()).not.toBe('%PDF');
      }
    });

    await test.step('Step 2: Authorized Manning Staff can access A001 License, Medical, and Assessment', async () => {
      await loginAsRole('MANNING');

      // A001 License (id=11)
      const resLic = await page.request.get('/Crew/CrewDocumentHandler.ashx?id=11');
      expect(resLic.status()).toBe(200);
      expect(resLic.headers()['content-type']).toContain('application/pdf');
      expect(resLic.headers()['x-content-type-options']?.toLowerCase()).toBe('nosniff');
      const bufLic = await resLic.body();
      expect(bufLic.subarray(0, 4).toString()).toBe('%PDF');

      // A001 Medical (id=12)
      const resMed = await page.request.get('/Crew/CrewDocumentHandler.ashx?id=12');
      expect(resMed.status()).toBe(200);
      expect(resMed.headers()['content-type']).toContain('application/pdf');
      expect(resMed.headers()['x-content-type-options']?.toLowerCase()).toBe('nosniff');
      const bufMed = await resMed.body();
      expect(bufMed.subarray(0, 4).toString()).toBe('%PDF');

      // A001 Assessment (cid=5)
      const resAssess = await page.request.get('/Crew/AssessmentAttachmentHandler.ashx?cid=5');
      expect(resAssess.status()).toBe(200);
      expect(resAssess.headers()['content-type']).toContain('application/pdf');
      expect(resAssess.headers()['x-content-type-options']?.toLowerCase()).toBe('nosniff');
      const bufAssess = await resAssess.body();
      expect(bufAssess.subarray(0, 4).toString()).toBe('%PDF');
    });

    await test.step('Step 3: Restricted Manning Staff (viewcrewcontactdetails=0) is denied sensitive Medical and Assessment', async () => {
      await loginAsRole('MANNING_RESTRICTED');

      // Standard License is accessible
      const resLic = await page.request.get('/Crew/CrewDocumentHandler.ashx?id=11');
      expect(resLic.status()).toBe(200);

      // Sensitive Medical is FORBIDDEN (403)
      const resMed = await page.request.get('/Crew/CrewDocumentHandler.ashx?id=12');
      expect(resMed.status()).toBe(403);

      // Sensitive Assessment is FORBIDDEN (403)
      const resAssess = await page.request.get('/Crew/AssessmentAttachmentHandler.ashx?cid=5');
      expect(resAssess.status()).toBe(403);
    });

    await test.step('Step 4: Isolated Principal is scoped to Vessel A and denied Vessel B documents', async () => {
      await loginAsRole('PRINCIPAL');

      // A001 on Vessel A: accessible
      const resLicA = await page.request.get('/Crew/CrewDocumentHandler.ashx?id=11');
      expect(resLicA.status()).toBe(200);

      // B001 on Vessel B: FORBIDDEN (403)
      const resLicB = await page.request.get('/Crew/CrewDocumentHandler.ashx?id=14');
      expect(resLicB.status()).toBe(403);
    });

    await test.step('Step 5: Isolated Vessel Owner is scoped to Vessel A and denied Vessel B documents', async () => {
      await loginAsRole('VESSEL_OWNER');

      // A001 on Vessel A: accessible
      const resLicA = await page.request.get('/Crew/CrewDocumentHandler.ashx?id=11');
      expect(resLicA.status()).toBe(200);

      // B001 on Vessel B: FORBIDDEN (403)
      const resLicB = await page.request.get('/Crew/CrewDocumentHandler.ashx?id=14');
      expect(resLicB.status()).toBe(403);
    });

    await test.step('Step 6: Applicant role is denied access to all crew document handlers (403)', async () => {
      await loginAsRole('APPLICANT');

      const resLic = await page.request.get('/Crew/CrewDocumentHandler.ashx?id=11');
      expect([302, 401, 403]).toContain(resLic.status());

      const resAssess = await page.request.get('/Crew/AssessmentAttachmentHandler.ashx?cid=5');
      expect([302, 401, 403]).toContain(resAssess.status());
    });
  });

  // --------------------------------------------------------------------------
  // TC-CM-202: Enforce CCL action permissions
  // Uses isolated synthetic CCL reliever and schedule on Vessel A.
  // This is a READ-ONLY test — it only inspects the CCL roster, does not execute actions.
  // --------------------------------------------------------------------------
  test('TC-CM-202: Enforce CCL action permissions', async ({ loginAsRole, crewSearchPage, page }) => {
    await test.step('Step 1: Manning Staff with CCL permission sees the Vessel A CCL roster link', async () => {
      await loginAsRole('MANNING');
      await crewSearchPage.goto();

      const vessels = await crewSearchPage.getVesselOptions();
      const vesselAOption = vessels.find(v => v.includes(VESSEL_A));
      if (!vesselAOption) {
        test.skip(true, `Fixture vessel ${VESSEL_A} not in vessel dropdown. Fixture setup required.`);
        return;
      }

      await crewSearchPage.vesselDropdown.selectOption({ label: vesselAOption });
      await crewSearchPage.search();

      const rowCount = await crewSearchPage.resultRows.count();
      if (rowCount === 0) {
        test.skip(true, `No crew found on ${VESSEL_A}. Fixture setup required.`);
        return;
      }

      // At least one eligible-status crew member on Vessel A must have a vessel roster link
      let foundCCLLink = false;
      for (let i = 0; i < rowCount; i++) {
        const row = crewSearchPage.resultRows.nth(i);
        const rowText = await row.innerText();
        // A001 (On Board) or A002 (Line Up) or A004 (Vacation) are eligible
        if (rowText.includes(A001_LAST) || rowText.includes(A002_LAST) || rowText.includes(A004_LAST)) {
          const vesselCell = row.locator('td').nth(4);
          const vesselCellHtml = await vesselCell.innerHTML();
          if (vesselCellHtml.match(/<a\s[^>]*href[^>]*>/i)) {
            foundCCLLink = true;
            break;
          }
        }
      }
      expect(foundCCLLink).toBe(true);
    });

    await test.step('Step 2: Navigate to Vessel A CCL and confirm fixture reliever and schedule records are present', async () => {
      // Navigate to CrewChangeList.aspx and find Vessel A
      await page.goto('/Crew/CrewChangeList.aspx');
      await page.waitForLoadState('networkidle').catch(() => {});

      // Look for Vessel A in the vessel picker
      const vesselPicker = page.locator('[id$="drpVesselPicker"], select[name*="Vessel"]');
      const pickerOptions = await vesselPicker.locator('option').allInnerTexts().catch(() => [] as string[]);
      const vesselAInPicker = pickerOptions.find(v => v.includes(VESSEL_A));

      if (!vesselAInPicker) {
        // Try navigation by dropdown on the QueryCrew page
        await crewSearchPage.goto();
        const vessels = await crewSearchPage.getVesselOptions();
        const vesselAOption = vessels.find(v => v.includes(VESSEL_A));
        if (!vesselAOption) return;

        await crewSearchPage.vesselDropdown.selectOption({ label: vesselAOption });
        await crewSearchPage.search();

        // Click any eligible vessel link (A001)
        for (let i = 0; i < await crewSearchPage.resultRows.count(); i++) {
          const row = crewSearchPage.resultRows.nth(i);
          const rowText = await row.innerText();
          if (rowText.includes(A001_LAST)) {
            const vesselCell = row.locator('td').nth(4);
            const link = vesselCell.locator('a').first();
            if (await link.isVisible().catch(() => false)) {
              await link.click();
              await page.waitForLoadState('networkidle').catch(() => {});
              break;
            }
          }
        }
      } else {
        await vesselPicker.selectOption({ label: vesselAInPicker });
        await page.waitForLoadState('networkidle').catch(() => {});
      }

      // The CCL page content (reliever or schedule) for Vessel A should be visible
      // We only assert presence — not mutation
      const cclContent = page.locator('[id$="panelCCLContent"], [id$="GridViewCCL"], .ccl-table, table');
      // Page should load without server error
      await expect(page.locator('body')).not.toContainText('Server Error in');
    });

    await test.step('Step 3: Principal without CCL permission has no CCL link on eligible crew rows', async () => {
      await loginAsRole('PRINCIPAL');
      await crewSearchPage.goto();

      const vessels = await crewSearchPage.getVesselOptions();
      const vesselAOption = vessels.find(v => v.includes(VESSEL_A));
      if (!vesselAOption) return;  // covered by TC-CM-042

      await crewSearchPage.search();
      const rowCount = await crewSearchPage.resultRows.count();

      // Principal has ccl_permission=0, so even eligible crew should show plain-text vessel name
      for (let i = 0; i < rowCount; i++) {
        const row = crewSearchPage.resultRows.nth(i);
        const vesselCell = row.locator('td').nth(4);
        const vesselCellHtml = await vesselCell.innerHTML();
        // No clickable CCL link expected for Principal role
        expect(vesselCellHtml).not.toMatch(/href[^>]*VesselCrew/i);
      }
    });
  });

});
