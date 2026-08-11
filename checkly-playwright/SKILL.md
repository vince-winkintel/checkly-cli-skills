---
name: checkly-playwright
description: Configure Playwright test suites with Checkly including playwright.config.ts integration, multiple projects, and full test suite deployment. Use when running complete Playwright test suites as checks, managing multiple browsers, or leveraging Playwright's full feature set. Triggers on playwright config, test suite, playwright project, multiple browsers.
---

# checkly playwright

Run full Playwright test suites as Checkly checks.

## Playwright Check Suite

Deploy entire Playwright test suite:

```typescript
// checkly.config.ts
export default defineConfig({
  checks: {
    playwrightConfigPath: './playwright.config.ts',
    playwrightChecks: [
      {
        name: 'E2E Test Suite',
        frequency: 10,
        testCommand: 'npm run test:e2e',
        locations: ['us-east-1', 'eu-west-1'],
        tags: ['e2e'],
      },
    ],
  },
})
```

## Playwright configuration

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test'

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
    { name: 'firefox', use: { browserName: 'firefox' } },
    { name: 'webkit', use: { browserName: 'webkit' } },
  ],
})
```

## Multiple projects

```typescript
playwrightChecks: [
  {
    name: 'Chromium Tests',
    testCommand: 'npx playwright test --project=chromium',
    frequency: 5,
  },
  {
    name: 'Cross-Browser Tests',
    testCommand: 'npx playwright test',
    frequency: 30,
  },
]
```

## Private package registries

For Playwright Check Suites, Checkly automatically bundles `.npmrc` from the workspace root and each workspace-member package root. Do not add those files manually to an `include` pattern. A `.npmrc` below a package root is not bundled because package managers do not read configuration from below the install directory.

Because the bundled file is uploaded for the cloud install, reference credentials through an environment variable rather than storing a token in plaintext:

```ini
@company:registry=https://registry.example.com/
//registry.example.com/:_authToken=${NPM_TOKEN}
```

Provide `NPM_TOKEN` through Checkly's locked environment variables or CI secrets. Changing a bundled `.npmrc` invalidates Checkly's workspace bundle cache.

## Dependency cache invalidation

Checkly keys installed dependencies from the lockfile, `package.json`, and `.npmrc`. If those inputs are unchanged but a deployed or scheduled Playwright Check Suite needs a persistent reinstall, change the top-level cache version in `checkly.config.ts`:

```typescript
export default defineConfig({
  projectName: 'My monitoring project',
  logicalId: 'my-monitoring-project',
  caching: {
    dependencyCache: {
      version: '2', // string or safe integer; change to invalidate
    },
  },
})
```

Do not place `caching` on an individual suite or check: one uploaded code bundle serves all Playwright Check Suites. Unset and empty-string versions leave the key unchanged. For a one-off reinstall during an ad-hoc run, use `--refresh-cache` on `checkly test`, `checkly pw-test`, `checkly trigger`, or `checkly checks run` instead.

## Related Skills

- See `checkly-checks` for individual browser checks
- See `checkly-test` for testing Playwright checks
