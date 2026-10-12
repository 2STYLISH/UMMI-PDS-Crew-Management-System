import { Page, Locator } from '@playwright/test';

export interface ActivityLogRow {
  timestamp: string;
  user: string;
  category: string;
  activity: string;
  ip: string;
}

export class ActivityLogsPage {
  readonly page: Page;
  readonly categoryDropdown: Locator;
  readonly dateFromInput: Locator;
  readonly dateToInput: Locator;
  readonly userInput: Locator;
  readonly searchButton: Locator;
  readonly resetButton: Locator;
  readonly exportButton: Locator;
  readonly countLabel: Locator;
  readonly logsTable: Locator;

  constructor(page: Page) {
    this.page = page;
    this.categoryDropdown = page.locator('[id$="drpdwnCategory"]');
    this.dateFromInput = page.locator('[id$="txtDateFrom"]');
    this.dateToInput = page.locator('[id$="txtDateTo"]');
    this.userInput = page.locator('[id$="txtUser"]');
    this.searchButton = page.locator('[id$="btnSearch"]');
    this.resetButton = page.locator('[id$="btnReset"]');
    this.exportButton = page.locator('[id$="btnExport"]');
    this.countLabel = page.locator('[id$="lblCount"]');
    this.logsTable = page.locator('[id$="gvLogs"]');
  }

  async goto() {
    await this.page.goto('/Settings/ActivityLogs.aspx');
    await this.page.waitForLoadState('networkidle').catch(() => {});
  }

  async filterByCategory(category: string) {
    await this.categoryDropdown.selectOption(category);
    await this.searchButton.click();
    await this.page.waitForLoadState('networkidle').catch(() => {});
  }

  async getLogRows(): Promise<ActivityLogRow[]> {
    const rows = this.logsTable.locator('tr').filter({ has: this.page.locator('td') });
    const count = await rows.count();
    const result: ActivityLogRow[] = [];
    for (let i = 0; i < count; i++) {
      const row = rows.nth(i);
      const cells = row.locator('td');
      if (await cells.count() >= 4) {
        result.push({
          timestamp: (await cells.nth(0).innerText()).trim(),
          user: (await cells.nth(1).innerText()).trim(),
          category: (await cells.nth(2).innerText()).trim(),
          activity: (await cells.nth(3).innerText()).trim(),
          ip: (await cells.count() >= 5 ? await cells.nth(4).innerText() : '').trim(),
        });
      }
    }
    return result;
  }

  async hasMatchingLog(options: {
    category?: string;
    activitySubstring?: string;
    userSubstring?: string;
  }): Promise<boolean> {
    const rows = await this.getLogRows();
    return rows.some(r => {
      const matchesCat = !options.category || r.category.toLowerCase().includes(options.category.toLowerCase());
      const matchesAct = !options.activitySubstring || r.activity.toLowerCase().includes(options.activitySubstring.toLowerCase());
      const matchesUsr = !options.userSubstring || r.user.toLowerCase().includes(options.userSubstring.toLowerCase());
      return matchesCat && matchesAct && matchesUsr;
    });
  }
}
