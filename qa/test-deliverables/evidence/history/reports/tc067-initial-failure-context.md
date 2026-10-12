# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: contact-restrictions.spec.ts >> Cycle 2 Contact Restrictions Test Suite (Azure Staging) >> TC-CM-067: Documentation Officer (viewcrewcontactdetails=0) - Contact & Statutory details hidden, non-sensitive profile loads
- Location: tests\cycle2\contact-restrictions.spec.ts:35:7

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: locator('span[id*="lblFullName"]')
Expected: visible
Timeout: 10000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" locator('span[id*="lblFullName"]') with timeout 10000ms
  - waiting for locator('span[id*="lblFullName"]')

```

```yaml
- navigation:
  - link "UMMI Logo UMMI Crew Management":
    - /url: ../Home.aspx
    - img "UMMI Logo"
    - text: UMMI Crew Management
  - navigation "Main navigation":
    - link " Dashboard":
      - /url: ../Home.aspx
    - button " Crew "
    - button " Personnel "
  - text: October 10, 2026 Documentation Officer Q
- text: Crew Search
- main:
  - heading " Crew Search" [level=2]
  - text:  Search Filters Last Name
  - textbox "Last name...": QA2B18_BatangasMatch
  - text: First Name
  - textbox "First name..."
  - text: Crew Status
  - combobox:
    - option "ALL" [selected]
    - option "ACTIVE"
    - option "INACTIVE"
    - option "ON BOARD"
    - option "ON VACATION"
    - option "APPLICANT"
    - option "LINE UP"
  - text: Availability
  - combobox:
    - option "ALL" [selected]
    - option "Available"
    - option "Not Available"
  - text: Rank Type
  - combobox:
    - option "ALL" [selected]
    - option "Deck"
    - option "Engine"
    - option "Rating"
    - option "Catering"
    - option "Cadet"
  - text: Rank
  - combobox:
    - option "ALL" [selected]
    - option "MASTER"
    - option "CHIEF ENGINEER"
    - option "BOSUN"
    - option "CHIEF COOK"
    - option "DECK CADET"
    - option "CHIEF OFFICER"
    - option "2ND ENGINEER"
    - option "AB SEAMAN"
    - option "STEWARD"
    - option "ENGINE CADET"
    - option "2ND OFFICER"
    - option "3RD ENGINEER"
    - option "OS"
    - option "3RD OFFICER"
    - option "4TH ENGINEER"
  - text: Province
  - combobox:
    - option "ALL" [selected]
    - option "Batangas"
    - option "Cavite"
    - option "Cebu"
    - option "Metro Manila"
    - option "Pangasinan"
  - text: City / Municipality
  - combobox:
    - option "ALL" [selected]
    - option "Alaminos"
    - option "Bacoor"
    - option "Batangas City"
    - option "Cebu City"
    - option "Dagupan City"
    - option "Imus"
    - option "Lapu-Lapu"
    - option "Lipa City"
    - option "Makati"
    - option "Mandaue"
    - option "Manila"
    - option "Quezon City"
  - text: Vessel Experience Type
  - combobox:
    - option "ALL" [selected]
    - option "BULK CARRIER EXPERIENCE"
    - option "CONTAINER SHIP EXPERIENCE"
    - option "GENERAL CARGO EXPERIENCE"
    - option "LNG/LPG CARRIER EXPERIENCE"
    - option "PASSENGER / RORO EXPERIENCE"
    - option "TANKER EXPERIENCE"
  - text: Vessel
  - combobox:
    - option "ALL" [selected]
    - option "MT MINDANAO"
    - option "MV CEBU PRIDE"
    - option "MV PACIFIC DAWN"
    - option "MV UMMI STAR"
    - option "QA-C2-RUN-20261001-C2P1-Vessel-A"
    - option "QA-C2-RUN-20261001-C2P1-Vessel-B"
  - text: Age Filter
  - spinbutton "Exact Age (e.g. 35)"
  - checkbox "Cadetship"
  - text: Cadetship
  - checkbox "JOCAP"
  - text: JOCAP
  - checkbox "Higher Lic."
  - text: Higher Lic.
  - button " Search"
  - button " Reset"
  - button " Export Excel"
  - strong: "1"
  - text: Crew Found
  - strong: "34"
  - text: Avg. Age ALL • ALL
  - group "Color legend":  Legend On Board Line Up On Vacation Active Inactive Other (e.g. Applicant)
  - table:
    - rowgroup:
      - row "Name Rank Status Vessel Age Last Vessel Status Date Sea Service Availability":
        - columnheader
        - columnheader "Name"
        - columnheader "Rank"
        - columnheader "Status"
        - columnheader "Vessel"
        - columnheader "Age"
        - columnheader "Last Vessel"
        - columnheader "Status Date"
        - columnheader "Sea Service"
        - columnheader "Availability"
      - row "Photo QA2B18_BatangasMatch, Maria Clara AB SEAMAN ACTIVE QA-C2-RUN-20261001-C2P1-Vessel-A 34 09/01/2026 0 yr(s) Available":
        - cell "Photo":
          - img "Photo"
        - cell "QA2B18_BatangasMatch, Maria Clara":
          - link "QA2B18_BatangasMatch, Maria Clara":
            - /url: ProfileViewer.aspx?ID=yzh-lpQb0KcQwxxRBmv2KMYCeUHiU5a_jDQLwdGG5VU%7e&Type=bZwxsV1H7z0UyG1faJs3sPqllsJeZDo53l3uQIO7hnA%7e
        - cell "AB SEAMAN"
        - cell "ACTIVE"
        - cell "QA-C2-RUN-20261001-C2P1-Vessel-A"
        - cell "34"
        - cell
        - cell "09/01/2026"
        - cell "0 yr(s)"
        - cell "Available"
```

# Test source

```ts
  1   | import { test, expect } from '@playwright/test';
  2   | import fs from 'fs';
  3   | import path from 'path';
  4   | 
  5   | const SCREENSHOT_DIR = path.resolve(__dirname, '../../evidence/screenshots/cycle2/batch18');
  6   | const TRACE_DIR = path.resolve(__dirname, '../../evidence/traces');
  7   | 
  8   | if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
  9   | if (!fs.existsSync(TRACE_DIR)) fs.mkdirSync(TRACE_DIR, { recursive: true });
  10  | 
  11  | async function loginAs(page, username, password) {
  12  |   if (!username || !password) throw new Error('Missing credentials for login');
  13  |   await page.goto('/login.aspx');
  14  |   await page.fill('#txtUsername', username);
  15  |   await page.fill('#txtPassword', password);
  16  |   await page.click('#btnLogin');
  17  |   await page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 20000 });
  18  | }
  19  | 
  20  | async function clickSearchAndWait(page) {
  21  |   await Promise.all([
  22  |     page.waitForResponse(res => res.url().includes('QueryCrew.aspx') && res.request().method() === 'POST'),
  23  |     page.locator('input[id*="btnSearch"]').click()
  24  |   ]);
  25  |   await page.waitForLoadState('load');
  26  |   await page.waitForLoadState('networkidle');
  27  |   await page.waitForTimeout(600);
  28  | }
  29  | 
  30  | test.describe.serial('Cycle 2 Contact Restrictions Test Suite (Azure Staging)', () => {
  31  | 
  32  |   // ==========================================================================
  33  |   // TC-CM-067: Documentation Officer with viewcrewcontactdetails = 0
  34  |   // ==========================================================================
  35  |   test('TC-CM-067: Documentation Officer (viewcrewcontactdetails=0) - Contact & Statutory details hidden, non-sensitive profile loads', async ({ page }) => {
  36  |     const user = process.env.QA2CONTACT_DOC_USER || 'qa2contact.doc.restricted';
  37  |     const pass = process.env.QA2CONTACT_DOC_PASSWORD;
  38  | 
  39  |     await page.context().tracing.start({ screenshots: true, snapshots: true });
  40  | 
  41  |     await loginAs(page, user, pass);
  42  | 
  43  |     // Open crew search
  44  |     await page.goto('/Crew/QueryCrew.aspx');
  45  |     await page.waitForLoadState('networkidle');
  46  | 
  47  |     // Query controlled QA2B18 crew record
  48  |     await page.fill('input[id*="txtLastName"]', 'QA2B18_BatangasMatch');
  49  |     await clickSearchAndWait(page);
  50  | 
  51  |     const crewRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BatangasMatch' });
  52  |     await expect(crewRow).toBeVisible();
  53  | 
  54  |     // Click normal encrypted profile link
  55  |     const profileLink = crewRow.locator('a[id*="lnkProfile"]');
  56  |     await expect(profileLink).toBeVisible();
  57  |     await profileLink.click();
  58  | 
  59  |     // If opens in new tab or same page
  60  |     const pages = page.context().pages();
  61  |     const targetPage = pages.length > 1 ? pages[pages.length - 1] : page;
  62  |     await targetPage.waitForLoadState('networkidle');
  63  | 
  64  |     // 1. Assert Contact Details section is completely HIDDEN
  65  |     const contactInfo = targetPage.locator('#divContactInfo, div[id$="divContactInfo"]');
  66  |     await expect(contactInfo).toHaveCount(0);
  67  | 
  68  |     // 2. Assert Statutory Details section is completely HIDDEN
  69  |     const statutoryInfo = targetPage.locator('#divStatutory, div[id$="divStatutory"]');
  70  |     await expect(statutoryInfo).toHaveCount(0);
  71  | 
  72  |     // 3. Assert Personal Notes section is completely HIDDEN
  73  |     const personalNotes = targetPage.locator('#divPersonalNotes, div[id$="divPersonalNotes"]');
  74  |     await expect(personalNotes).toHaveCount(0);
  75  | 
  76  |     // 4. Assert permitted non-sensitive profile content loads cleanly
  77  |     const fullNameLabel = targetPage.locator('span[id*="lblFullName"]');
> 78  |     await expect(fullNameLabel).toBeVisible();
      |                                 ^ Error: expect(locator).toBeVisible() failed
  79  |     await expect(fullNameLabel).toContainText('QA2B18_BatangasMatch');
  80  | 
  81  |     const rankLabel = targetPage.locator('span[id*="lblRank"]');
  82  |     await expect(rankLabel).toBeVisible();
  83  |     await expect(rankLabel).toHaveText('AB SEAMAN');
  84  | 
  85  |     const basicInfoCard = targetPage.locator('.card-header-ummi:has-text("Basic Information")');
  86  |     await expect(basicInfoCard).toBeVisible();
  87  | 
  88  |     await targetPage.screenshot({
  89  |       path: path.join(SCREENSHOT_DIR, 'tc067-doc-officer-contact-hidden.png'),
  90  |       fullPage: true
  91  |     });
  92  | 
  93  |     await page.context().tracing.stop({
  94  |       path: path.join(TRACE_DIR, 'tc067-trace.zip')
  95  |     });
  96  |   });
  97  | 
  98  |   // ==========================================================================
  99  |   // TC-CM-069: Admin with viewcrewcontactdetails = 0
  100 |   // ==========================================================================
  101 |   test('TC-CM-069: Admin (viewcrewcontactdetails=0) - Contact & Statutory details hidden, non-sensitive profile loads', async ({ page }) => {
  102 |     const user = process.env.QA2CONTACT_ADMIN_USER || 'qa2contact.admin.restricted';
  103 |     const pass = process.env.QA2CONTACT_ADMIN_PASSWORD;
  104 | 
  105 |     await page.context().tracing.start({ screenshots: true, snapshots: true });
  106 | 
  107 |     await loginAs(page, user, pass);
  108 | 
  109 |     // Open crew search
  110 |     await page.goto('/Crew/QueryCrew.aspx');
  111 |     await page.waitForLoadState('networkidle');
  112 | 
  113 |     // Query controlled QA2B18 crew record
  114 |     await page.fill('input[id*="txtLastName"]', 'QA2B18_BatangasMatch');
  115 |     await clickSearchAndWait(page);
  116 | 
  117 |     const crewRow = page.locator('table[id*="GridViewQueryCrew"] tr', { hasText: 'QA2B18_BatangasMatch' });
  118 |     await expect(crewRow).toBeVisible();
  119 | 
  120 |     // Click normal encrypted profile link
  121 |     const profileLink = crewRow.locator('a[id*="lnkProfile"]');
  122 |     await expect(profileLink).toBeVisible();
  123 |     await profileLink.click();
  124 | 
  125 |     const pages = page.context().pages();
  126 |     const targetPage = pages.length > 1 ? pages[pages.length - 1] : page;
  127 |     await targetPage.waitForLoadState('networkidle');
  128 | 
  129 |     // 1. Assert Contact Details section is completely HIDDEN
  130 |     const contactInfo = targetPage.locator('#divContactInfo, div[id$="divContactInfo"]');
  131 |     await expect(contactInfo).toHaveCount(0);
  132 | 
  133 |     // 2. Assert Statutory Details section is completely HIDDEN
  134 |     const statutoryInfo = targetPage.locator('#divStatutory, div[id$="divStatutory"]');
  135 |     await expect(statutoryInfo).toHaveCount(0);
  136 | 
  137 |     // 3. Assert Personal Notes section is completely HIDDEN
  138 |     const personalNotes = targetPage.locator('#divPersonalNotes, div[id$="divPersonalNotes"]');
  139 |     await expect(personalNotes).toHaveCount(0);
  140 | 
  141 |     // 4. Assert permitted non-sensitive profile content loads cleanly
  142 |     const fullNameLabel = targetPage.locator('span[id*="lblFullName"]');
  143 |     await expect(fullNameLabel).toBeVisible();
  144 |     await expect(fullNameLabel).toContainText('QA2B18_BatangasMatch');
  145 | 
  146 |     const rankLabel = targetPage.locator('span[id*="lblRank"]');
  147 |     await expect(rankLabel).toBeVisible();
  148 |     await expect(rankLabel).toHaveText('AB SEAMAN');
  149 | 
  150 |     const basicInfoCard = targetPage.locator('.card-header-ummi:has-text("Basic Information")');
  151 |     await expect(basicInfoCard).toBeVisible();
  152 | 
  153 |     await targetPage.screenshot({
  154 |       path: path.join(SCREENSHOT_DIR, 'tc069-admin-contact-hidden.png'),
  155 |       fullPage: true
  156 |     });
  157 | 
  158 |     await page.context().tracing.stop({
  159 |       path: path.join(TRACE_DIR, 'tc069-trace.zip')
  160 |     });
  161 |   });
  162 | 
  163 |   // ==========================================================================
  164 |   // TC-CM-071: Super-Admin with viewcrewcontactdetails = 0
  165 |   // ==========================================================================
  166 |   test('TC-CM-071: Super-Admin (viewcrewcontactdetails=0) - Contact & Statutory details hidden, non-sensitive profile loads', async ({ page }) => {
  167 |     const user = process.env.QA2CONTACT_SUPERADMIN_USER || 'qa2contact.superadmin.restricted';
  168 |     const pass = process.env.QA2CONTACT_SUPERADMIN_PASSWORD;
  169 | 
  170 |     await page.context().tracing.start({ screenshots: true, snapshots: true });
  171 | 
  172 |     await loginAs(page, user, pass);
  173 | 
  174 |     // Open crew search
  175 |     await page.goto('/Crew/QueryCrew.aspx');
  176 |     await page.waitForLoadState('networkidle');
  177 | 
  178 |     // Query controlled QA2B18 crew record
```