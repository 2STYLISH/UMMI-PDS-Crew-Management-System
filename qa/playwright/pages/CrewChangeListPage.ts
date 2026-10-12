import { Page, Locator, expect } from '@playwright/test';

export class CrewChangeListPage {
  readonly page: Page;
  readonly vesselDropdown: Locator;
  readonly vesselPickerDropdown: Locator;
  readonly vesselPickerPanel: Locator;
  readonly backToSearchLink: Locator;
  readonly cclTable: Locator;
  readonly vesselCrewTable: Locator;

  constructor(page: Page) {
    this.page = page;
    this.vesselDropdown = page.locator('[id$="drpdwnVessel"], select[name*="Vessel"]');
    this.vesselPickerDropdown = page.locator('[id$="drpVesselPicker"]');
    this.vesselPickerPanel = page.locator('[id$="panelVesselPicker"]');
    this.backToSearchLink = page.locator('a:has-text("Back to Search"), a:has-text("Back to Crew Search")');
    this.cclTable = page.locator('[id$="GridViewCCL"], .ccl-table, [id$="panelCCLContent"] table');
    this.vesselCrewTable = page.locator('[id$="GridViewVesselCrew"], .vessel-crew-table');
  }


  async gotoCCL() {
    await this.page.goto('/Crew/CrewChangeList.aspx');
  }

  async gotoVesselCrew(vesselId?: string) {
    const url = vesselId ? `/Crew/VesselCrew.aspx?VesselID=${encodeURIComponent(vesselId)}` : '/Crew/VesselCrew.aspx';
    await this.page.goto(url);
  }
}
