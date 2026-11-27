# Project validation and alert entitlements

`npx checkly validate` is a visible core command in CLI **10.5.0+**. It reports configuration and construct errors/warnings without running checks or deploying resources; it is not a deployment plan. The command existed earlier, so this is a visibility minimum, not its introduction version.

`npx checkly validate` authenticates, reads account/runtime APIs, and loads and executes project/config code. It does not deploy resources or run checks, but it is not isolated, offline, or universally side-effect-free. Review project code and authorize its execution and API access before invoking it.

Use `--config` (`-c`) for an alternate config path. Runtime dependency verification defaults to true (`--verify-runtime-dependencies`, also controlled by `CHECKLY_VERIFY_RUNTIME_DEPENDENCIES`). Do not disable checks to work around account entitlement refusal. Missing check locations produce warnings; fatal diagnostics exit 1.

## Diagnostics

For `validate`, `test`, `pw-test`, `deploy` and `import plan`, shared project validation stops the spinner before printing diagnostics. Config diagnostics precede project/construct diagnostics. On failure, the order is spinner failure, diagnostics, closing error, exit 1; on success, the spinner succeeds before warnings print. A blank line separates the spinner status from diagnostics, and one blank line precedes the closing error. Output spacing is not a machine-readable interface.

## Alert entitlement rules

CLI **10.5.0+** refuses managed alert channels with `Integration not included in your plan` when the account reports their integration as `entitled: false`, including previously deployed channels. This blocks `validate`, `test`, `pw-test` and deploy planning. Slack `connected` and `entitled` are separate: a connected app can still be refused, and a disconnected, unentitled app can report both errors. Email, plain webhook channels and `AlertChannel.fromId()` references are exempt from this entitlement check. An omitted integration or `entitled` field skips it; absence of a diagnostic is not proof that alerts work. Never bypass the gate by changing channel type, reference style or validation behavior. Obtain explicit approval before removing alert channels or changing plans; never automatically upgrade or pay.

The check applies to Slack webhook and Slack App channels, PagerDuty, Opsgenie, SMS and phone calls. Recognized webhook integration types are Microsoft Teams, Discord, Telegram, FireHydrant, GitLab, Spike.sh, Splunk, Coralogix, ilert, incident.io and Rootly. Specialized Teams, Telegram and incident.io constructs inherit webhook mapping. Unknown webhook types have no mapping and skip this check; this is an implementation limit, never a workaround.

A `SlackAppAlertChannel` with nonempty `slackChannels` separately fails when the API reports the Slack app disconnected. Missing Slack integration state skips that connection check. Empty destinations skip only the connection check, not the entitlement check. Connection does not grant a plan entitlement.

Read all attributed channel diagnostics together. Confirm the intended account and reported entitlement, then present remediation for approval. Removing a managed channel from code can delete it on deployment; review the subsequent plan and alert coverage. The CLI's billing hint grants no authorization for a purchase or plan change.

## Immutable source evidence

These summaries come from official source, not an installed CLI or exact help capture:

- [Validate command and flags](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/commands/validate.ts), [core help expectation](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/e2e/__tests__/help.spec.ts).
- [Authentication and diagnostic order](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/commands/authCommand.ts), [output-order tests](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/commands/__tests__/validate-project-output.spec.ts).
- [Config loading](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/services/checkly-config-loader.ts), [project parsing](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/services/project-parser.ts).
- [Entitlement predicate and reference class](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/constructs/alert-channel.ts), [account response contract](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/rest/accounts.ts), [diagnostic](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/constructs/construct-diagnostics.ts).
- [Webhook mapping](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/constructs/webhook-alert-channel.ts), [Slack connection check](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/constructs/slack-app-alert-channel.ts), [entitlement tests](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/constructs/__tests__/alert-channel-integration.spec.ts), [Slack tests](https://github.com/checkly/checkly-cli/blob/0d8b571a18ee1ef2a35b6ac991349ab2abdb4384/packages/cli/src/constructs/__tests__/slack-app-alert-channel.spec.ts).
