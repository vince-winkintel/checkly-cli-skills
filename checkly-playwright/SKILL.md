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
  bundle: {
    packages: {
      embed: ['@acme/*', 'acme-*-utils', 'legacy-private-pkg@2.1.0'],
    },
  },
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

## Structured check intent

`PlaywrightCheck` supports durable intent for Checkly root-cause analysis and check repair:

```typescript
import { PlaywrightCheck } from 'checkly/constructs'

new PlaywrightCheck('critical-browser-journey', {
  name: 'Critical Browser Journey',
  playwrightConfigPath: './playwright.config.ts',
  intent: {
    goal: 'Verify that users can complete the critical browser journey.',
    constraints: [
      {
        type: 'MUST_PRESERVE',
        statement: 'Do not weaken the final success assertion.',
      },
    ],
  },
})
```

The shorthand `checks.playwrightChecks` entries do not expose `intent`; use an explicit `PlaywrightCheck` construct when intent is required. Intent does not replace Playwright assertions. Omit it to preserve existing backend-authored intent, provide an object to set/update it, or use `intent: null` to clear it deliberately. A goal is required and limited to 2,000 trimmed characters. Constraints use exact uppercase types `REQUIRED_OUTCOME` or `MUST_PRESERVE`, with at most 20 of each type and 1,000 trimmed characters per statement.

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

For normal runner-side installs, provide `NPM_TOKEN` through Checkly's locked environment variables. For CLI-side downloads such as embedded tarballs, provide it to the machine running `checkly deploy` or `checkly test`, typically through local or CI secrets. Changing a bundled `.npmrc` invalidates Checkly's workspace bundle cache.

### Embedding private package tarballs

Use top-level `bundle.packages.embed` when a Playwright Check Suite depends on private-registry packages that Checkly runners cannot otherwise fetch. This is for packages in the Playwright suite dependency install, not for individual browser checks or multi-step checks:

```typescript
export default defineConfig({
  projectName: 'My monitoring project',
  logicalId: 'my-monitoring-project',
  bundle: {
    packages: {
      embed: [
        '@acme/*',
        'acme-*-utils',
        '@acme/legacy-client@2.1.0',
      ],
    },
  },
  checks: {
    playwrightConfigPath: './playwright.config.ts',
    playwrightChecks: [
      {
        logicalId: 'checkout-suite',
        name: 'Checkout Suite',
        testCommand: 'npx playwright test',
        frequency: 10,
      },
    ],
  },
})
```

Each entry is resolved against the workspace-root `pnpm-lock.yaml` or `package-lock.json`. Use a package name to embed every lockfile version for that package, an exact `name@version` pin for one version, or name wildcards such as `@acme/*`, `acme-*`, and `@acme/*-utils`. A wildcard `*` matches characters inside one package-name segment and does not cross `/`, so `@acme/*` stays inside the `@acme` scope.

Only pnpm lockfile versions 6 and 9 and npm lockfile versions 2 and 3 are supported. Yarn and Bun lockfiles fail validation. Every `embed` entry must match at least one embeddable registry package: an entry that matches nothing, or whose only matches cannot be embedded, fails validation. If a wildcard also matches workspace members, those matches are skipped silently. Git, file, URL, or integrity-less matches are skipped with a warning when the same entry also selects embeddable packages; the runner must still be able to fetch the skipped dependencies.

List every private package the runner cannot fetch, including transitive private dependencies. Embedding one package does not automatically embed the private packages it depends on. Workspace packages, git dependencies, file or URL dependencies, and lockfile entries without integrity hashes are not embeddable registry tarballs; keep those reachable through normal bundling or through a runner-accessible registry instead.

The CLI verifies embedded tarballs against the lockfile integrity hash. It uses the local cache first, then npm's cache, then the registry using `.npmrc` registry and auth settings. The default Checkly cache is the workspace root's `node_modules/.cache/checkly`, with a per-user cache fallback; set `CHECKLY_CACHE_DIR` only when you need a writable or shared cache location. Keep registry credentials in `.npmrc` as environment-variable references. On a cold cache, the machine running `checkly deploy` or `checkly test` must have those variables in its own environment; locked Checkly variables do not authenticate this CLI-side download. Locked variables remain appropriate for runner-side installation of non-embedded private packages.

Changing the resolved embedded tarball set changes the runner dependency-cache key. If package inputs are unchanged but a deployed or scheduled suite needs a reinstall, use `caching.dependencyCache.version`; for one ad-hoc run, use `--refresh-cache`.

## Dependency cache invalidation

Checkly keys installed dependencies from the lockfile, `package.json`, `.npmrc`, and the resolved `bundle.packages.embed` tarball set. If those inputs are unchanged but a deployed or scheduled Playwright Check Suite needs a persistent reinstall, change the top-level cache version in `checkly.config.ts`:

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
