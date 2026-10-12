import { Page, Locator, expect } from '@playwright/test';

export class CrewProfilePage {
  readonly page: Page;
  readonly assessmentsTabButton: Locator;
  readonly personalDocsTabButton: Locator;
  readonly licensesTabButton: Locator;
  readonly medicalDocsTabButton: Locator;
  readonly trainingDocsTabButton: Locator;
  readonly seaServiceTabButton: Locator;
  readonly assessmentsGrid: Locator;
  readonly personalDocsGrid: Locator;
  readonly licenseDocsGrid: Locator;
  readonly medicalDocsGrid: Locator;
  readonly trainingDocsGrid: Locator;

  constructor(page: Page) {
    this.page = page;
    this.assessmentsTabButton = page.locator('button.nav-link:has-text("Assessments"), button[onclick*="tabComments"]');
    this.personalDocsTabButton = page.locator('button.nav-link:has-text("Personal Docs"), button[onclick*="tabDocPersonal"]');
    this.licensesTabButton = page.locator('button.nav-link:has-text("Licenses"), button[onclick*="tabDocLicense"]');
    this.medicalDocsTabButton = page.locator('button.nav-link:has-text("Medical"), button[onclick*="tabDocMedical"]');
    this.trainingDocsTabButton = page.locator('button.nav-link:has-text("Training"), button[onclick*="tabDocTraining"]');
    this.seaServiceTabButton = page.locator('button.nav-link:has-text("Sea Service"), button[onclick*="tabSeaService"]');
    this.assessmentsGrid = page.locator('[id$="gvComments"], .comments-table');
    this.personalDocsGrid = page.locator('[id$="gvDocPersonal"]');
    this.licenseDocsGrid = page.locator('[id$="gvDocLicense"]');
    this.medicalDocsGrid = page.locator('[id$="gvDocMedical"]');
    this.trainingDocsGrid = page.locator('[id$="gvDocTraining"]');
  }


  async gotoCrew(crewId: string | number) {
    await this.page.goto(`/Crew/ProfileViewer.aspx?id=${crewId}`);
  }

  async openAssessmentsTab() {
    await this.assessmentsTabButton.click();
    await expect(this.assessmentsGrid).toBeVisible();
  }

  async openDocumentsTab() {
    await this.documentsTabButton.click();
  }
}
