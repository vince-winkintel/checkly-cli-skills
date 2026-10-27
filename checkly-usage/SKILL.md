---
name: checkly-usage
description: Inspect Checkly account plans, entitlements, feature limits, organization contract usage, credits, projections, and per-period consumption with npx checkly account plan and account usage. Use when reviewing plan availability, private-location or feature entitlements, usage terms, credit budgets, projected exhaustion, usage by account or check type, date ranges, or paginated usage data. Triggers on checkly account plan, checkly account usage, plan limits, entitlements, usage terms, usage summary, usage series, Checkly credits, contract usage, credit projection.
---

# Checkly account plan and usage

Use `account plan` for account entitlements and limits. Use `account usage` for organization contract terms, measured credit use and projections. Confirm the effective account with `npx checkly whoami --output json` before interpreting results. Usage requires a current user/service credential with `usage:read` permission; legacy account keys are not accepted.

## Command map

| Command | Purpose | Default output |
|---|---|---|
| `account plan [KEY]` | Plan, add-ons, entitlements and location limits | `table` |
| `account usage terms` | Paginated list of terms, optionally overlapping dates | `table` |
| `account usage term <id>` | One term UUID, pricing rules and covered accounts | `detail` |
| `account usage summary` | Credit totals, pricing breakdowns and coverage gaps | `detail` |
| `account usage series` | Per-period rows with composable dimensions | `table` |
| `account usage projections <id>` | Project credit consumption for one term UUID | `detail` |

All accept `--output json` or `--output md`; table-default commands also accept `table`, detail-default commands accept `detail`. Results go to stdout and diagnostic errors to stderr. Invalid inputs exit 2; runtime failures exit 1.

## Account plan

```bash
npx checkly account plan --output json
npx checkly account plan --search browser --output json
npx checkly account plan <ENTITLEMENT_KEY> --output json
npx checkly account plan --disabled --output table
```

`--type` accepts `metered` or `flag`. A positional key cannot be combined with `--type`, `--search` or `--disabled`. An unknown key exits 1. Unfiltered JSON has `plan`, `planDisplayName`, `addons`, optional `locations`, and `entitlements[]`. Filtered JSON is an entitlement array; a key lookup returns one object. Inspect `locations.all[].available` and `locations.maxPerCheck` for location limits.

## Select terms and dates

```bash
npx checkly account usage terms --from 2026-01-01 --to 2026-03-31 --output json
npx checkly account usage term <term-uuid> --output json
npx checkly account usage summary --from 2026-01-01 --to 2026-03-31 --usage-terms-id <term-uuid> --output json
npx checkly account usage series --from 2026-01-01 --to 2026-03-31 --group-by account,checkType --include runs --output json
npx checkly account usage projections <term-uuid> --as-of 2026-03-31 --output json
```

Dates are inclusive UTC `YYYY-MM-DD` calendar dates, with `from <= to`. For `terms`, neither date has a default: the range selects **all overlapping terms**, not one contract covering the end date. For `summary`/`series`, `--to` defaults to today and `--from` to the earliest selected usage start, or the end date. Pin both dates for comparisons and pagination.

`projections --as-of` defaults to **yesterday UTC**. Today and future dates are rejected: projections use a completed UTC day. Report the selected term and as-of date alongside any estimate; do not describe a projection as measured usage.

## Range and series flags

`summary` and `series` accept repeated or comma-separated `--usage-terms-id` UUIDs, `--account-id` GUIDs and `--pricing-rule` keys (up to 100 values per list). `--account-id` filters covered accounts; it does not switch authentication. Set `CHECKLY_ACCOUNT_ID` before launching the CLI to select the authenticated account.

Pricing keys: `apiChecks`, `multistepChecks`, `browserChecks`, `playwrightCheckSuites`, `uptimeMonitors`, `aiInvocations`, `statusPages`, `statusPageAdditionalServices`, `statusPageAdditionalSubscribers`, `additionalSms`, `additionalPhoneAlerts`.

Migration warning: `--check-type` was removed and is rejected. Select charges with `--pricing-rule`, or break them down with `series --group-by checkType`.

| Series flag | Values |
|---|---|
| `--interval` | `total`, `day` (default), `week`, `month` |
| `--group-by` | Comma-separated `account`, `usageTerm`, `pricingRule`, `checkType`; `none` for no grouping. Default `account,checkType`. |
| `--include` | `runs`, `calculations`, or both; repeat or comma-separate. |
| `--limit`, `-l` | 1–500, default 100; also on `terms`. |
| `--cursor` | Nonempty next-page cursor; also on `terms`. |

Continue only when `pagination.nextId` is non-null. Reuse effective dates and every selection, grouping, include, interval and limit from page one (or the printed continuation command). Do not pass the string `null` as a cursor.

## JSON contract

These are abbreviated structural examples, not captured responses:

```jsonc
// terms: list wrapper; term <id>: one object from data
{
  "data": [{
    "id": "term-uuid", "name": "Organization",
    "accounts": [{ "id": "account-guid", "name": "Account" }],
    "contractStartDate": "2026-01-01", "contractEndDate": "2026-12-31",
    "usageStartDate": "2026-01-01", "creditBudget": 100000,
    "standardCreditsPerUnit": 1, "premiumCreditsPerUnit": 2,
    "packageModel": "credits", "pricingRules": {}
  }],
  "pagination": { "nextId": null, "length": 1 }
}
// summary
{
  "period": { "from": "2026-01-01", "to": "2026-03-31" },
  "usageTermsIds": ["term-uuid"],
  "totals": { "creditsUsed": 123 },
  "breakdown": [],
  "coverage": { "gaps": [] }
}
// series
{
  "data": [{
    "periodStart": "2026-01-01", "periodEnd": "2026-01-01",
    "dimensions": { "accountId": "account-guid", "checkType": "API" },
    "creditsUsed": 12, "contributions": []
  }],
  "pagination": { "nextId": null, "length": 1 },
  "period": { "from": "2026-01-01", "to": "2026-03-31" },
  "usageTermsIds": ["term-uuid"],
  "interval": "day", "groupBy": ["account", "checkType"],
  "coverage": { "gaps": [] }
}
```

- `summary.totals.creditsUsed` is nullable. Summary has no `percentOfBudget`, meters or projections. Its `breakdown[]` includes term ID, pricing-rule key, period, pricing rule, calculations and credits used, with optional account ID.
- `usageTermsIds` is a list on summary/series. Join each ID to `term <id>` or `terms.data[]`; do not assume one contract.
- Series `dimensions` carries selected account, term, pricing-rule and check-type dimensions. Rows use `creditsUsed`, not nested credits. `interval` and `groupBy` are top-level, with `groupBy` an array.
- `runs` appears only with `--include runs` and can be null; available counters include `totalRuns`, `finalRuns`, `retryRuns`, `cancelledRuns`, `degradedRuns`, `failedRuns`, `errorRuns`, `abortedRuns`, and `overMaxResponseTimeRuns`. `--include calculations` adds pricing details to contributions.
- `coverage.gaps[]` contains `{ from, to }` ranges; preserve gaps when summarizing coverage. It replaces the old series warnings array. Treat null credits/budgets/rates/projections as unknown, never zero.
- Projections are a separate response: singular `usageTermsId`, `asOf`, nullable `period`, `weeksSinceStart`, `weeksRemaining`, `creditsUsed`, `remainingCredits`, `budgetedDailyCredits`, and `windows` (`sinceStart`, `last30Days`, `last7Days`, `last1Day`). Each window includes observed days, average daily credits, credits used, projected contract-end credits/remaining credits/percent, annual budget percent and weeks until exhaustion. Projection values can be null.

## Troubleshooting

| Signal | Action |
|---|---|
| `NO_USAGE_TERMS` | List terms and choose available term IDs or a covered date range; a missing detail/projection ID does not mean no contracts exist. |
| `USAGE_TERMS_CONFLICT` | Choose non-overlapping terms with `--usage-terms-id` or narrow the range. |
| `ACCOUNT_NOT_IN_USAGE_TERMS` | Correct the filter using the term's covered accounts. |
| `INVALID_CURSOR` | Restart with pinned effective dates and all original flags. |
| `INVALID_RANGE` | Correct the range described by the API. |
| `USAGE_STORE_UNAVAILABLE` | Retry later; do not infer zero usage. |
| Unauthorized / inaccessible account | Verify the effective account and current user/service credentials without logging keys. |
| Bare permission failure | Verify `usage:read` permission on the active account. |

See `checkly-auth` for account overrides and `checkly-members` for membership inspection.
