import { test } from '@playwright/test';

test('Test QueryCrew filter execution on staging', async ({ page }) => {
  const user = process.env.UMMI_MANNING_USER || 'demo.manning';
  const pass = process.env.UMMI_MANNING_PASSWORD || '';
  await page.goto('/login.aspx');
  await page.fill('#txtUsername', user);
  await page.fill('#txtPassword', pass);
  await page.click('#btnLogin');
  await page.waitForURL(/\/(Home|QueryCrew)\.aspx/i, { timeout: 15000 });

  await page.goto('/Crew/QueryCrew.aspx');
  await page.waitForLoadState('networkidle');

  // 1. Initial count
  let count = await page.locator('span[id*="lblCrewCount"]').textContent();
  console.log('Default count:', count);

  // 2. Filter by Rank = MASTER
  await page.selectOption('select[id*="drpdwnRank"]', { label: 'MASTER' });
  await page.click('input[id*="btnSearch"]');
  await page.waitForLoadState('networkidle');
  count = await page.locator('span[id*="lblCrewCount"]').textContent();
  console.log('Count for Rank=MASTER:', count);

  // 3. Filter by Status = ON BOARD
  await page.selectOption('select[id*="drpdwnCrewStatus"]', { label: 'ON BOARD' });
  await page.click('input[id*="btnSearch"]');
  await page.waitForLoadState('networkidle');
  count = await page.locator('span[id*="lblCrewCount"]').textContent();
  console.log('Count for Status=ON BOARD:', count);

  // 4. Test Province dropdown options
  const provOptions = await page.locator('select[id*="drpdwnProvince"] option').allTextContents();
  console.log('Province options count:', provOptions.length, 'Samples:', provOptions.slice(0, 5));

  // 5. Select first non-ALL province
  if (provOptions.length > 1) {
    const provName = provOptions[1].trim();
    console.log('Selecting province:', provName);
    await page.selectOption('select[id*="drpdwnProvince"]', { label: provName });
    await page.waitForLoadState('networkidle');
    const cityOptions = await page.locator('select[id*="drpdwnCity"] option').allTextContents();
    console.log(`Cities for ${provName}: count=${cityOptions.length}, Samples:`, cityOptions.slice(0, 5));

    await page.click('input[id*="btnSearch"]');
    await page.waitForLoadState('networkidle');
    count = await page.locator('span[id*="lblCrewCount"]').textContent();
    console.log(`Count for Province=${provName}:`, count);
  }
});
