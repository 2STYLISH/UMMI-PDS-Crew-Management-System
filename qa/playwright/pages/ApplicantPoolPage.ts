import { Page, Locator, expect } from '@playwright/test';

export class ApplicantPoolPage {
  readonly page: Page;
  readonly lastNameInput: Locator;
  readonly firstNameInput: Locator;
  readonly rankTypeDropdown: Locator;
  readonly rankDropdown: Locator;
  readonly searchButton: Locator;
  readonly resetButton: Locator;
  readonly manageLinksButton: Locator;
  readonly linkStatusFilterDropdown: Locator;
  readonly linksGrid: Locator;
  readonly applicantsGrid: Locator;

  constructor(page: Page) {
    this.page = page;
    this.lastNameInput = page.locator('[id$="txtLastName"]');
    this.firstNameInput = page.locator('[id$="txtFirstName"]');
    this.rankTypeDropdown = page.locator('[id$="drpdwnRankType"]');
    this.rankDropdown = page.locator('[id$="drpdwnRank"]');
    this.searchButton = page.locator('[id$="btnSearch"]');
    this.resetButton = page.locator('[id$="btnReset"]');
    this.manageLinksButton = page.locator('[id$="btnManageLinks"]');
    this.linkStatusFilterDropdown = page.locator('[id$="drpdwnLinkStatusFilter"]');
    this.linksGrid = page.locator('[id$="gvLinks"]');
    this.applicantsGrid = page.locator('[id$="gvApplicants"]');
  }



  async goto() {
    await this.page.goto('/Applicant/ApplicantPool.aspx');
  }

  async openManageLinks() {
    await this.manageLinksButton.click();
    await expect(this.linkStatusFilterDropdown).toBeVisible();
  }
}
