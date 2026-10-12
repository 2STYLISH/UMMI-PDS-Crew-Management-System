import { test as base, Page } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import { CrewSearchPage } from '../pages/CrewSearchPage';
import { CrewProfilePage } from '../pages/CrewProfilePage';
import { ApplicantPoolPage } from '../pages/ApplicantPoolPage';
import { CrewChangeListPage } from '../pages/CrewChangeListPage';
import { ActivityLogsPage } from '../pages/ActivityLogsPage';
import { UserRole } from './roles';

type Fixtures = {
  loginPage: LoginPage;
  crewSearchPage: CrewSearchPage;
  crewProfilePage: CrewProfilePage;
  applicantPoolPage: ApplicantPoolPage;
  crewChangeListPage: CrewChangeListPage;
  activityLogsPage: ActivityLogsPage;
  loginAsRole: (role: UserRole) => Promise<Page>;
};

export const test = base.extend<Fixtures>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },
  crewSearchPage: async ({ page }, use) => {
    await use(new CrewSearchPage(page));
  },
  crewProfilePage: async ({ page }, use) => {
    await use(new CrewProfilePage(page));
  },
  applicantPoolPage: async ({ page }, use) => {
    await use(new ApplicantPoolPage(page));
  },
  crewChangeListPage: async ({ page }, use) => {
    await use(new CrewChangeListPage(page));
  },
  activityLogsPage: async ({ page }, use) => {
    await use(new ActivityLogsPage(page));
  },
  loginAsRole: async ({ page }, use) => {
    const login = async (role: UserRole): Promise<Page> => {
      const loginPage = new LoginPage(page);
      await loginPage.loginAs(role);
      return page;
    };
    await use(login);
  },
});

export { expect } from '@playwright/test';
