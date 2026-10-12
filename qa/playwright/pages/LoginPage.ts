import { Page, Locator, expect } from '@playwright/test';
import { UserRole, getCredentialsForRole } from '../fixtures/roles';

export class LoginPage {
  readonly page: Page;
  readonly usernameInput: Locator;
  readonly passwordInput: Locator;
  readonly signInButton: Locator;
  readonly alertDanger: Locator;

  constructor(page: Page) {
    this.page = page;
    this.usernameInput = page.locator('#txtUsername');
    this.passwordInput = page.locator('#txtPassword');
    this.signInButton = page.locator('input[type="submit"][value="Sign In"], #btnLogin');
    this.alertDanger = page.locator('.alert-danger, [id$="lblMessage"], .login-error');
  }

  async goto() {
    await this.page.context().clearCookies();
    await this.page.goto('/login.aspx');
    await expect(this.usernameInput).toBeVisible();
  }


  async login(username?: string, password?: string) {
    if (!username || !password) {
      throw new Error('Username or password was not provided for login.');
    }
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await Promise.all([
      this.page.waitForNavigation({ waitUntil: 'load' }).catch(() => {}),
      this.signInButton.click(),
    ]);
  }

  async loginAs(role: UserRole) {
    const creds = getCredentialsForRole(role);
    if (!creds.username || !creds.password) {
      throw new Error(`Credentials for role "${role}" are not configured in environment variables.`);
    }
    await this.goto();
    await this.login(creds.username, creds.password);
  }
}
