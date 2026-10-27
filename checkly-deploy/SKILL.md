---
name: checkly-deploy
description: Deploy Checkly checks to production with npx checkly deploy, including force deployment, preview changes, and CI/CD integration strategies. Use when deploying monitoring checks, updating production configuration, or integrating with deployment pipelines. Triggers on checkly deploy, deploy checks, production deployment, CI/CD deployment.
---

# checkly deploy

Deploy project definitions to Checkly with a reviewed, property-level plan. These commands contact Checkly; `validate` checks configuration but is not a deploy preview.

## Review and apply

```bash
npx checkly validate
npx checkly deploy --preview
# Machine-readable plan (does not deploy)
npx checkly deploy --dry-run > deploy-plan.json
# Apply a reviewed plan using the token returned by the preview
npx checkly deploy --plan-token <plan-token>
```

These are command examples, not captured terminal output. A preview or dry run uploads neither code bundles nor Playwright snapshots. An ordinary deploy parses, validates and bundles locally, requests a plan, asks for confirmation, then uploads and applies that plan. The plan marks `+` creates, `~` updates, `-` deletes and `=` baseline writes, and shows property and script diffs without revealing secrets.

Planning is on by default. Unchanged resources are not written. If the account changes between planning and applying, the CLI refuses the stale plan. An unpinned `--force` run can make a new plan and retry; a run pinned with `--plan-token` stops instead. Preview again and review the new changes before retrying.

The first planned deploy, including the first after `--no-plan`, writes existing resources once to establish a baseline. Identical resources show `=` and count under “to set a baseline”; changed resources show `~`. Payload changes can also produce updates with the note `payload format changed (CLI upgrade)`. Review resets carefully.

A plan with nothing to apply exits 0 without confirmation, including in CI/agent mode without `--force`. It prints `No changes.` and ends with `Project "<name>" is up to date.` It still records deployment state and renews the comparison baseline. Explicit scheduling with scope `all` can run unchanged checks subject to frequency/threshold filters.

## Confirmation and output

In a terminal, the plan and `Apply these changes?` prompt go to stderr. In CI or agent mode, a deploy that needs approval returns exit **3** with `status: "confirmation_required"`, planned changes and a `confirmCommand` pinned to the plan token when available. Present the changes and run that command verbatim after authorization. Exit **2** means invalid flags or arguments; **1** means failure. Do not treat exit 3 as success or retry it blindly with `--force`.

`--force` skips confirmation; it does not disable planning or bypass a supplied plan token. Use it for already authorized automation. Final results go to stdout; progress, warnings, hints, errors and interactive plans/prompts go to stderr. `--dry-run` emits a JSON envelope on stdout: `status: "dry_run"`, `changes`, `confirmCommand`, and (when planned) `preview: { planToken, diff }`. An unplanned fallback has no `preview` object. `--preview` emits a human-readable plan and a command to apply the token later.

## Options

| Flag | Contract |
|---|---|
| `--preview`, `-p` | Show changes without applying them. |
| `--dry-run` | Print a JSON preview without deploying. |
| `--plan` / `--no-plan` | Planning defaults on. Opting out writes every resource. |
| `--plan-token` | Require the supplied plan token to match; unavailable with `--no-plan`. |
| `--fail-on-drift` / `--no-fail-on-drift` | Refuse overwriting changes made in Checkly since the previous planned deploy. |
| `--prune-unmanaged-relations` | Delete externally added alert subscriptions/private-location assignments; requires planning. |
| `--preserve-resources` | Detach resources removed from code, preserving resources and run history for UI management. |
| `--force`, `-f` | Skip confirmation in authorized automation. |
| `--output`, `-o` | Show changes after deployment; a boolean, not an output-format selector. |
| `--verbose`, `-v` | Include resource names and IDs. |
| `--config`, `-c` | Select the project configuration. |
| `--verify-runtime-dependencies` / `--no-verify-runtime-dependencies` | Runtime dependency validation defaults on. |
| `--cancel-in-progress-deployment` | Intentionally supersede an in-progress deployment instead of waiting. |

Migration warning: `--prune-relations` was renamed to `--prune-unmanaged-relations`. Without pruning, unmanaged subscriptions and assignments are kept and listed in the plan.

If planning is unavailable, ordinary deploys may fall back with a warning. `--plan-token`, relation pruning and drift protection require a plan and fail rather than silently dropping that protection.

## Drift protection and writing web changes into code

```bash
# For an authorized pipeline that must not overwrite web edits
npx checkly deploy --force --fail-on-drift
# Review drift without applying
npx checkly deploy --preview --fail-on-drift
```

`--fail-on-drift` exits 1 and writes nothing if the deploy would overwrite externally edited or deleted resources. `CHECKLY_FAIL_ON_DRIFT=1` enables it across a pipeline; `--no-fail-on-drift` overrides the environment. It cannot be used with `--no-plan`. `--preview` prints the plan before failing on drift; `--dry-run` ignores this guard and reports changes in JSON. Baseline-only writes have no previous baseline to compare, so produce a warning instead.

When web edits can be represented in code, the interactive prompt offers **Update my code with the changes made in Checkly**. This edits construct files in place, preserves style and emits helpers such as `Frequency`, `RetryStrategyBuilder` and `AssertionBuilder`. It then stops without deploying. Review `git diff` before another deploy. References, secrets and computed values that cannot be safely rewritten are listed for manual migration; a write-back error may leave some files updated, so review them even on failure.

## Properties owned by the deployment

Omitted values are reset to the following defaults; omission does not preserve a web-only edit. Put intended settings into code before applying the plan.

| Resource | Defaults when omitted |
|---|---|
| API, browser, multistep checks and `CheckGroupV1` | `retryStrategy`: one immediate retry in another region. |
| Monitors and `PlaywrightCheck` | No CLI retries; Playwright handles its own retries. |
| Checks | Empty `description` and `intent`; `aiAutoRepairEnabled` follows the account setting. |
| Alert channels | `sendRecovery: true`, `sendFailure: true`, `sendDegraded: false`, `sslExpiry: false`, `sslExpiryThreshold: 30`. |
| `PrivateLocation` | No `proxyUrl`. |
| `Dashboard` | Empty `customUrl`, `customDomain`, `logo`, `favicon`, `link`, `header`, `description`. |
| `MaintenanceWindow` | `timezone: 'UTC'`, no `repeatEndsAt`; changing timezone while active fails until it ends. |

Removing `group` from a `PlaywrightCheck` also removes the deployed group membership. See `checkly-constructs` for removed-property migration and `shouldFail` restrictions.

## Immediate scheduling is opt-in

Deploying configures ongoing monitoring according to each check's schedule, but does not trigger an immediate run by default.

| Flag | Meaning |
|---|---|
| `--schedule-on-deploy` / `--no-schedule-on-deploy` | Enable immediate post-deploy runs; default off. |
| `--schedule-on-deploy-scope=changed\|all` | Default `changed`: created/updated checks only. `all` includes unchanged checks. |
| `--schedule-on-deploy-threshold=<n\|auto>` | Schedule none if the eligible count exceeds the threshold. Heartbeats do not count. `auto` currently selects 500; server cap 2000. |
| `--schedule-on-deploy-min-frequency=<n\|auto>` | Skip checks running more frequently than this many minutes. `0` includes every frequency; `auto` currently selects 10. |

Threshold and minimum-frequency values must be non-negative whole numbers or `auto`. Explicit scheduling sub-options without `--schedule-on-deploy` are invalid (exit 2). Scope and frequency filters apply before the threshold. The CLI reports counts and reasons for skipped scheduling; server-selected limits can change.

```bash
# Explicitly schedule all eligible checks, including frequent ones, after deployment
npx checkly deploy --schedule-on-deploy --schedule-on-deploy-scope=all --schedule-on-deploy-min-frequency=0
```

## Authorized CI deployment

Set `CHECKLY_API_KEY` and `CHECKLY_ACCOUNT_ID` before starting the CLI. Install the locked project dependencies, run the intended tests, and apply only after they pass:

```bash
npm ci
npx checkly test && npx checkly deploy --force --fail-on-drift
```

An empty test selection fails by default. Do not suppress it in a gate intended to prove tests ran. Jenkins, TeamCity and AWS CodeBuild are detected alongside other CI providers; `CI=false`, `0`, `no` or `off` disables CI detection even on provider hosts. Prefer serialized deployment jobs per project.

## Removing resources and projects

Normal deployment deletes resources removed from code and their run history. Use `--preserve-resources` to detach them instead. Review deletions in the plan before authorizing deployment.

```bash
npx checkly deploy --preview --preserve-resources
npx checkly deploy --preserve-resources
# Decommission a project only when explicitly intended
npx checkly destroy
# Keep its resources as account-level resources
npx checkly destroy --preserve-resources
```

`destroy` also accepts `--force`, `--config` and `--cancel-in-progress-deployment`. It follows asynchronous progress, waits on concurrent operations and treats an already-missing project as deleted. `validate` is not a preview of deletion. A transient lock while verifying a deployment is retried up to three times. Failure to retrieve a heartbeat ping URL after success produces a warning rather than invalidating the deployment.

## Related skills

See `checkly-test`, `checkly-auth`, `checkly-config`, and `checkly-import` for test gates, credentials, defaults and existing-resource adoption.
