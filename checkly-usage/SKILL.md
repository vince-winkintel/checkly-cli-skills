---
name: checkly-usage
description: Inspect Checkly organization contract usage, credits, projections, and per-period consumption with npx checkly account usage. Use when reviewing usage terms, credit budgets, projected exhaustion, usage by account or check type, date ranges, or paginated usage data. Triggers on checkly account usage, usage terms, usage summary, usage series, Checkly credits, contract usage, credit projection.
---

# Checkly account usage

Use the read-only `npx checkly account usage` commands to inspect organization contract terms, credit consumption, projections, and grouped usage series.

## Preconditions

```bash
npx checkly whoami
npx checkly account usage terms --output json
```

Confirm the active account before interpreting organization-wide usage. Usage reporting requires a user or service API key and an Owner or Admin role; legacy account API keys are not accepted. Never print credential values while troubleshooting access.

## Command map

| Command | Purpose | Default output |
|---|---|---|
| `npx checkly account usage terms` | Show contract dates, usage start date, credit budget/rates, and covered accounts | `detail` |
| `npx checkly account usage summary` | Show totals for a date range and credit projections as of today | `detail` |
| `npx checkly account usage series` | Show per-period usage grouped by account and/or check type | `table` |

All three commands support JSON output for automation. `terms` and `summary` also support Markdown; `series` supports table, JSON, and Markdown.

## Recommended review workflow

```bash
# 1. Identify the terms that cover today
npx checkly account usage terms --output json

# 2. Review totals and projections for those terms
npx checkly account usage summary --output json

# 3. Break consumption down by account and check type
npx checkly account usage series \
  --interval month \
  --group-by account,checkType \
  --limit 100 \
  --output json
```

Report the contract period and credit budget before consumption percentages or projections. Distinguish measured usage from projections, which are calculated as of today.

## Terms and historical contracts

`--to YYYY-MM-DD` selects the usage terms covering that inclusive date; it does not name a usage-terms ID.

```bash
npx checkly account usage terms --to 2026-03-31 --output json
```

If no terms cover the requested date, first inspect known contract dates and choose a date inside the intended contract. Do not imply the organization has no contract merely because one historical date is uncovered.

## Summary filters

```bash
npx checkly account usage summary \
  --from 2026-01-01 \
  --to 2026-01-31 \
  --account-id <account-id> \
  --check-type API \
  --output json
```

- Dates are inclusive and must use `YYYY-MM-DD`; `--from` cannot be after `--to`.
- Without `--from`, the range begins at the selected terms' usage start date.
- Repeat `--account-id` and `--check-type`, or provide comma-separated values.
- Supported check types are `API`, `BROWSER`, `HEARTBEAT`, `MULTI_STEP`, `PLAYWRIGHT`, `TCP`, `ICMP`, `DNS`, `URL`, `GRPC`, `SSL`, `TRACEROUTE`, and `AGENTIC`.
- JSON summary output contains the raw API summary and does not require the extra terms lookup used to enrich human-readable output.

## Series grouping and pagination

```bash
npx checkly account usage series \
  --from 2026-01-01 \
  --to 2026-03-31 \
  --interval week \
  --group-by account,checkType \
  --account-id <account-id> \
  --limit 100 \
  --output json
```

- `--interval` accepts `total`, `day`, `week`, or `month`; the default is `day`.
- `--group-by` accepts `account`, `checkType`, or `account,checkType`; the default is `account,checkType`.
- `--limit` must be between 1 and 500; the default is 100.
- JSON output returns a cursor envelope with `data`, `pagination.nextId`, `pagination.length`, `usageTermsId`, `period`, and `warnings`.
- When `pagination.nextId` is present, repeat every original filter/grouping flag and add `--cursor <nextId>`. Cursors are bound to the resolved query; changing flags invalidates them.
- Preserve and report warning codes such as partial-window or unknown-budget warnings rather than presenting the data as complete.

Example continuation:

```bash
npx checkly account usage series \
  --from 2026-01-01 \
  --to 2026-03-31 \
  --interval week \
  --group-by account,checkType \
  --account-id <account-id> \
  --limit 100 \
  --cursor <nextId> \
  --output json
```

## Output selection

- Prefer `--output json` for calculations, filtering, pagination, and evidence capture.
- Use `--output detail` for human-readable terms or summary drilldowns.
- Use `--output md` when the result will be pasted into a report; Markdown suppresses terminal navigation hints.
- Human-readable series output resolves account names when grouped by account. Retain account IDs from JSON when exact attribution matters.

## Troubleshooting

- **401 / legacy key rejected:** authenticate with a user or service API key, then rerun `npx checkly whoami`.
- **403:** the active account lacks the required Owner or Admin role.
- **No usage terms:** verify the selected `--to` date and account membership.
- **Conflicting terms:** choose a `--to` date covered by only one contract.
- **Invalid cursor:** rerun the first page with the original flags and use its newly returned cursor.
- **Usage store unavailable:** preserve the error and retry later; do not infer zero usage.
