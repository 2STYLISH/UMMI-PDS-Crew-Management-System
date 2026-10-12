import { test, expect } from '@playwright/test';
import { LoginPage } from './page-objects/LoginPage';

test('Inspect deployed CrewChangeList.aspx', async ({ page }) => {
  const login = new LoginPage(page);
  await login.goto();
  await login.login(process.env.UMMI_SUPERADMIN_USER || '', process.env.UMMI_SUPERADMIN_PASSWORD || '');
  await page.waitForLoadState('networkidle');

  await page.goto('/Crew/CrewChangeList.aspx');
  await page.waitForLoadState('networkidle');

  const content = await page.content();
  const hasSignOn = content.includes('Sign-On') || content.includes('Sign On') || content.includes('btnSignOn') || content.includes('modalSignOn') || content.includes('sign_on');
  console.log('CrewChangeList has Sign-On text or IDs:', hasSignOn);

  // Print all button texts on the page
  const buttons = await page.locator('button, input[type="button"], input[type="submit"]').allInnerTexts();
  console.log('Buttons on CCL:', Array.from(new Set(buttons)).filter(b => b.trim().length > 0));

  // Check modals
  const modals = await page.locator('.modal').evaluateAll(els => els.map(e => ({ id: e.id, title: e.querySelector('.modal-title')?.textContent?.trim() })));
  console.log('Modals on CCL:', modals);
});
