import { Page, Locator, expect } from '@playwright/test';

export class CrewSearchPage {
  readonly page: Page;
  readonly lastNameInput: Locator;
  readonly firstNameInput: Locator;
  readonly statusDropdown: Locator;
  readonly availabilityDropdown: Locator;
  readonly rankTypeDropdown: Locator;
  readonly rankDropdown: Locator;
  readonly vesselDropdown: Locator;
  readonly searchButton: Locator;
  readonly resetButton: Locator;
  readonly exportExcelButton: Locator;
  readonly crewChangeListLink: Locator;
  readonly resultsTable: Locator;
  readonly resultRows: Locator;
  readonly emptyStateText: Locator;
  readonly summaryCountLabel: Locator;

  constructor(page: Page) {
    this.page = page;
    this.lastNameInput = page.locator('[id$="txtLastName"]');
    this.firstNameInput = page.locator('[id$="txtFirstName"]');
    this.statusDropdown = page.locator('[id$="drpdwnCrewStatus"]');
    this.availabilityDropdown = page.locator('[id$="drpdwnCrewAvailability"]');
    this.rankTypeDropdown = page.locator('[id$="drpdwnRankType"]');
    this.rankDropdown = page.locator('[id$="drpdwnRank"]');
    this.vesselDropdown = page.locator('[id$="drpdwnVessel"]');
    this.searchButton = page.locator('[id$="btnSearch"]');
    this.resetButton = page.locator('[id$="btnReset"]');
    this.exportExcelButton = page.locator('[id$="btnExportExcel"]');
    this.crewChangeListLink = page.locator('[id$="lnkCrewChangeList"]');
    this.resultsTable = page.locator('[id$="GridViewQueryCrew"]');
    this.resultRows = page.locator('[id$="GridViewQueryCrew"] tr').filter({ has: page.locator('td a[href*="ProfileViewer"]') });
    this.emptyStateText = page.locator('[id$="GridViewQueryCrew"] div:has-text("No crew found"), [id$="GridViewQueryCrew"] .empty-state');
    this.summaryCountLabel = page.locator('[id$="lblCrewCount"]');
  }

  async goto() {
    await this.page.goto('/Crew/QueryCrew.aspx');
    await expect(this.searchButton).toBeVisible();
  }

  async search() {
    await Promise.all([
      this.page.waitForResponse(res => res.url().includes('QueryCrew.aspx') && res.request().method() === 'POST'),
      this.searchButton.click(),
    ]);
    await this.page.waitForLoadState('networkidle').catch(() => {});
  }

  async selectRankType(rankTypeLabel: string) {
    await Promise.all([
      this.page.waitForResponse(res => res.url().includes('QueryCrew.aspx') && res.request().method() === 'POST'),
      this.rankTypeDropdown.selectOption({ label: rankTypeLabel }),
    ]);
    await this.page.waitForLoadState('networkidle').catch(() => {});
  }

  async reset() {
    await Promise.all([
      this.page.waitForResponse(res => res.url().includes('QueryCrew.aspx') && res.request().method() === 'POST'),
      this.resetButton.click(),
    ]);
    await this.page.waitForLoadState('networkidle').catch(() => {});
  }

  async getVesselOptions(): Promise<string[]> {
    return await this.vesselDropdown.locator('option').allInnerTexts();
  }

  async getRankOptions(): Promise<string[]> {
    return await this.rankDropdown.locator('option').allInnerTexts();
  }

  async getRankTypeOptions(): Promise<string[]> {
    return await this.rankTypeDropdown.locator('option').allInnerTexts();
  }
}
