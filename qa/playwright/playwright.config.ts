import { defineConfig, devices } from '@playwright/test';
import fs from 'fs';
import path from 'path';

// Load .env file if present
const envPath = path.resolve(__dirname, '.env');
if (fs.existsSync(envPath) && typeof process.loadEnvFile === 'function') {
  process.loadEnvFile(envPath);
}

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './tests',
  /* Run tests sequentially to avoid data races and session conflicts */
  fullyParallel: false,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* No automatic retries to avoid unintentional duplicate operations */
  retries: 0,
  /* Single worker for controlled end-to-end execution */
  workers: 1,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
    ['html', { open: 'never' }],
    ['json', { outputFile: 'evidence/results.json' }]
  ],
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('')`. */
    baseURL: 'https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net',

    /* Installed Chrome browser channel */
    channel: 'chrome',

    /* Evidence capture settings */
    screenshot: 'only-on-failure',
    // Video disabled because playwright ffmpeg CDN download times out in this environment
    video: 'off',
    trace: 'retain-on-failure',
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        channel: 'chrome',
      },
    },
  ],
});

