---
name: checkly-advanced
description: Advanced Checkly CLI features including retry strategies, reporters, environment variables, bundling, and custom patterns. Use when implementing complex retry logic, customizing test output, managing secrets, or troubleshooting advanced scenarios. Triggers on retry strategy, reporter, environment variables, bundling, advanced configuration.
---

# checkly advanced

Advanced Checkly CLI features and patterns.

## Retry Strategies

API/browser/multistep checks and `CheckGroupV1` default to one immediate retry in another region. Monitors and Playwright suites default to no CLI retries. Use `RetryStrategyBuilder.singleRetry({ baseBackoffSeconds: 0, sameRegion: false })` for the immediate cross-region behavior or `RetryStrategyBuilder.noRetries()` to disable it. Bare `singleRetry()` waits 60 seconds in the same region.

### Fixed retry

```typescript
import { RetryStrategyBuilder } from 'checkly/constructs'

retryStrategy: RetryStrategyBuilder.fixedStrategy({
  baseBackoffSeconds: 60,
  maxRetries: 2,
  maxDurationSeconds: 600,
  sameRegion: true,
})
```

### Linear backoff

```typescript
retryStrategy: RetryStrategyBuilder.linearStrategy({
  baseBackoffSeconds: 30,
  maxRetries: 3,
  maxDurationSeconds: 600,
  sameRegion: false,
})
```

### Exponential backoff

```typescript
retryStrategy: RetryStrategyBuilder.exponentialStrategy({
  baseBackoffSeconds: 10,
  maxRetries: 5,
  maxDurationSeconds: 600,
  sameRegion: true,
})
```

### Conditional retries

```typescript
// Retry only on network errors (API checks only)
retryStrategy: RetryStrategyBuilder.fixedStrategy({
  maxRetries: 2,
  onlyOn: 'NETWORK_ERROR',
})
```

## Reporters

With no explicit reporter, CI and agents use `ci`, other runs use `list`. Results go to stdout, diagnostics to stderr. Timed-out checks produce `Timed out` in JSON / `T` in dot output and exit 1. `--max-failures` on test/trigger reports unfinished checks separately; see `checkly-test`.

### List reporter (default outside CI and agent mode)

```bash
npx checkly test --reporter=list
```

### Dot reporter (compact)

```bash
npx checkly test --reporter=dot
```

### JSON reporter

```bash
npx checkly test --reporter=json > results.json
```

### GitHub Actions reporter

```bash
npx checkly test --reporter=github
```

### CI reporter

```bash
npx checkly test --reporter=ci
```

### GitHub Check re-run metadata

GitHub annotations from `--reporter=github` are separate from test-session repository metadata. With `CHECKLY_GITHUB_REPORT=true` or `1` (case-insensitive and whitespace-trimmed), the CLI includes a `github` object in the session's repository information when repository information is available. It forwards these optional environment values:

- `CHECKLY_GITHUB_JOB_ID` → `github.jobId`: the GitHub job identifier, distinct from the existing job name in `CHECKLY_GITHUB_JOB` and workflow run ID in `CHECKLY_GITHUB_RUN_ID`.
- `CHECKLY_GITHUB_RERUN` → `github.rerun`: the re-run mode, such as `repository-dispatch`; this is not a boolean CLI flag.

Both values are trimmed; unset, empty, or whitespace-only values are omitted from the serialized payload. `checkly-action` supplies them when the workflow opts into Re-run on its Checkly GitHub Check; the backend uses the metadata to re-run the dispatching job. Forwarding values alone does not configure the action, grant GitHub permissions, or trigger a re-run. Keep re-run opt-in and workflow permissions explicitly reviewed: a re-run can repeat network checks and other job side effects. Do not invent a job ID, add broad permissions, or enable re-runs just to populate this metadata.

## Environment Variables

### Global variables

```typescript
// checkly.config.ts
checks: {
  environmentVariables: [
    { key: 'API_URL', value: 'https://api.example.com' },
    { key: 'API_KEY', value: process.env.API_KEY!, locked: true },
  ],
}
```

### Group-level variables

```typescript
const group = new CheckGroup('api-group', {
  environmentVariables: [
    { key: 'SERVICE', value: 'api' },
  ],
})
```

### Check-level variables

```typescript
new ApiCheck('check', {
  environmentVariables: [
    { key: 'ENDPOINT', value: '/status' },
  ],
})
```

## Validation Options

```bash
# Verify runtime dependencies
npx checkly test --verify-runtime-dependencies

# Show verbose output
npx checkly test --verbose

# Validate without running
npx checkly validate
```

## Custom patterns

### Dynamic check generation

```typescript
const endpoints = ['users', 'products', 'orders']

endpoints.forEach(endpoint => {
  new ApiCheck(`${endpoint}-api`, {
    name: `${endpoint} API`,
    request: {
      url: `https://api.example.com/${endpoint}`,
    },
  })
})
```

### Shared alert configurations

```typescript
// alerts.ts
export const criticalAlerts = [emailChannel, slackChannel, pagerduty]

// check.ts
new ApiCheck('critical-check', {
  alertChannels: criticalAlerts,
})
```

## Related Skills

- See `checkly-constructs` for construct system details
- See `checkly-test` for testing options
- See `checkly-checks` for applying advanced features
