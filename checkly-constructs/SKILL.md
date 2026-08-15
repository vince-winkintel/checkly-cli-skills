---
name: checkly-constructs
description: Understand the Checkly constructs system including resource lifecycle, logical IDs, configuration inheritance, and the Session/Project abstraction. Use when debugging construct issues, understanding resource management, or working with advanced patterns. Triggers on constructs, logical ID, resource management, project structure.
---

# checkly constructs

The Checkly constructs system provides type-safe abstractions for monitoring resources.

## Core concepts

### Construct hierarchy

```
Construct (base)
├── Check
│   ├── RuntimeCheck
│   │   ├── ApiCheck
│   │   ├── BrowserCheck
│   │   └── MultiStepCheck
│   └── PlaywrightCheck
├── Monitor
│   ├── HeartbeatMonitor
│   ├── TcpMonitor
│   ├── DnsMonitor
│   └── UrlMonitor
├── CheckGroup
└── AlertChannel
```

### Logical IDs

Every construct needs a unique logical ID:

```typescript
new ApiCheck('api-status-check', {  // <- logical ID
  name: 'API Status Check',  // <- display name
})
```

**Rules:**
- Must be unique within resource type
- Pattern: `[A-Za-z0-9_-/#.]+`
- Use descriptive IDs: `'homepage-check'` not `'check-1'`

## Construct lifecycle

1. **Construction**: Instance created and registered
2. **Validation**: Configuration checked for errors
3. **Bundling**: Code and dependencies packaged
4. **Synthesis**: Converted to API payload
5. **Deployment**: Created/updated in Checkly

## Structured check intent

Use `intent` to give Checkly root-cause analysis and check-repair features durable guidance about what a check is meant to verify. Intent supplements descriptions and executable assertions; it does not replace either.

```typescript
new ApiCheck('dashboard-api', {
  name: 'Dashboard API',
  intent: {
    goal: 'Verify that authenticated users can open the dashboard.',
    constraints: [
      {
        type: 'REQUIRED_OUTCOME',
        statement: 'The dashboard displays the account overview.',
      },
      {
        type: 'MUST_PRESERVE',
        statement: 'Do not weaken the authentication assertion.',
      },
    ],
  },
  request: {
    method: 'GET',
    url: 'https://example.com/api/dashboard',
  },
})
```

Intent is supported by `ApiCheck`, `BrowserCheck`, `MultiStepCheck`, `PlaywrightCheck`, `TcpMonitor`, `DnsMonitor`, `IcmpMonitor`, `UrlMonitor`, and `GrpcMonitor`. It is not exposed on `AgenticCheck`, `HeartbeatMonitor`, `SslMonitor`, or `TracerouteMonitor`.

Deployment semantics are deliberate:

- Omit `intent` to leave any existing backend-authored intent unchanged.
- Provide an object to set or update intent.
- Set `intent: null` to explicitly clear it.

The CLI trims surrounding whitespace. `goal` is required and limited to 2,000 characters after trimming. Constraints use exact uppercase types `REQUIRED_OUTCOME` or `MUST_PRESERVE`; each statement is limited to 1,000 characters, and each type may appear at most 20 times. Unknown fields or constraint types fail validation.

## Session and Project

The Session singleton manages global state:

```typescript
// Internal - you don't normally interact with this
Session.current().addConstruct(check)
```

The Project aggregates all constructs:

```typescript
// Internal - happens automatically
project.addResource('check', check)
```

## Configuration inheritance

```typescript
// checkly.config.ts - global
checks: {
  frequency: 10,
  locations: ['us-east-1'],
}

// CheckGroup - group-level
const group = new CheckGroup('api', {
  frequency: 5,  // Overrides global
})

// Check - check-level
new ApiCheck('critical-api', {
  group: group,
  frequency: 1,  // Overrides group
})
```

## Related Skills

- See `checkly-checks` for practical check creation
- See `checkly-groups` for organization
