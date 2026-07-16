---
name: checkly-monitors
description: Create health and infrastructure monitors including heartbeat, TCP, DNS, URL, gRPC, SSL, and traceroute monitors. Use for uptime monitoring, service availability, TLS certificate validation, gRPC health or behavior checks, network path diagnostics, DNS validation, and infrastructure health without browser code. Triggers on heartbeat, TCP monitor, DNS monitor, URL monitor, gRPC monitor, SSL monitor, certificate expiry, traceroute, health check, uptime monitoring.
---

# checkly monitors

Health and infrastructure checks without browser code execution.

## Monitor types

| Monitor | Use case | Checks |
|---------|----------|--------|
| **Heartbeat** | Periodic ping expected | Inbound webhook calls |
| **TCP** | Port connectivity | Socket connection |
| **DNS** | Domain resolution | DNS records |
| **URL** | HTTP availability | Status code only |
| **gRPC** | gRPC service health or unary behavior | Status, health, response, metadata, latency |
| **SSL** | Certificate and TLS posture | Expiry, trust, hostname, protocol, cipher, key |
| **Traceroute** | Network path diagnostics | Latency, hop count, packet loss |

## Heartbeat monitors

Expect periodic pings from your application.

```typescript
import { HeartbeatMonitor } from 'checkly/constructs'

new HeartbeatMonitor('app-heartbeat', {
  name: 'App Heartbeat',
  period: 300,
  periodUnit: 'seconds',
  grace: 60,
})
```

Your application pings the generated heartbeat URL:

```bash
curl -X POST https://ping.checklyhq.com/heartbeats/{YOUR_ID}
```

## TCP monitors

Check TCP port connectivity.

```typescript
import { TcpMonitor } from 'checkly/constructs'

new TcpMonitor('database-tcp', {
  name: 'Database TCP Check',
  host: 'db.example.com',
  port: 5432,
  frequency: 5,
})
```

## DNS monitors

Validate DNS records.

```typescript
import { DnsMonitor } from 'checkly/constructs'

new DnsMonitor('dns-check', {
  name: 'DNS A Record',
  host: 'example.com',
  recordType: 'A',
  expectedValues: ['93.184.216.34'],
})
```

Use `recordType: 'HTTPS'` when validating HTTPS/SVCB-style service-binding records (RFC 9460):

```typescript
new DnsMonitor('https-dns-check', {
  name: 'DNS HTTPS Record',
  host: 'example.com',
  recordType: 'HTTPS',
  expectedValues: ['1 . alpn="h2,h3"'],
})
```

## URL monitors

Check simple HTTP availability.

```typescript
import { UrlMonitor } from 'checkly/constructs'

new UrlMonitor('url-check', {
  name: 'Homepage URL Check',
  url: 'https://example.com',
  method: 'GET',
})
```

## gRPC monitors

Use `GrpcMonitor` for a unary method (`BEHAVIOR`) or the standard gRPC health-check service (`HEALTH`). The request `url` is a hostname without a scheme.

```typescript
import { GrpcAssertionBuilder, GrpcMonitor } from 'checkly/constructs'

new GrpcMonitor('grpc-health', {
  name: 'gRPC Health',
  degradedResponseTime: 3000,
  maxResponseTime: 10000,
  request: {
    url: 'grpc.example.com',
    port: 50051,
    grpcConfig: {
      mode: 'BEHAVIOR',
      tls: true,
      serviceDefinition: 'REFLECTION',
      method: '/grpc.health.v1.Health/Check',
    },
    assertions: [
      GrpcAssertionBuilder.statusCode().equals(0),
      GrpcAssertionBuilder.responseTime().lessThan(5000),
      GrpcAssertionBuilder.responseMessage('$.status').equals('SERVING'),
    ],
  },
})
```

- In `HEALTH` mode, optionally set `grpcConfig.service`; omit it to query overall server health.
- In `BEHAVIOR` mode, set `grpcConfig.method` and use `serviceDefinition: 'REFLECTION'` or `'PROTO_FILE'`.
- Use `GrpcAssertionBuilder` for status, health status, response message/body, response metadata, and response-time assertions.

## SSL monitors

Use `SslMonitor` to validate certificate expiry, chain trust, hostname verification, TLS version, cipher suite, key size, signature algorithm, fingerprints, and OCSP stapling. The request `hostname` has no scheme.

```typescript
import {
  CipherSuite,
  SslAssertionBuilder,
  SslMonitor,
  TlsVersion,
} from 'checkly/constructs'

new SslMonitor('tls-certificate', {
  name: 'TLS Certificate',
  degradedResponseTime: 3000,
  maxResponseTime: 10000,
  request: {
    hostname: 'example.com',
    port: 443,
    ipFamily: 'IPv4',
    sslConfig: {
      alertDaysBeforeExpiry: 30,
      skipChainValidation: false,
    },
    assertions: [
      SslAssertionBuilder.certExpiresInDays().greaterThan(30),
      SslAssertionBuilder.chainTrusted().equals(true),
      SslAssertionBuilder.hostnameVerified().equals(true),
      SslAssertionBuilder.tlsVersion().equals(TlsVersion.TLS1_3),
      SslAssertionBuilder.cipherSuite().equals(CipherSuite.TLS_AES_256_GCM_SHA384),
    ],
  },
})
```

- Response-time thresholds are top-level monitor properties and measure TLS handshake time.
- Put certificate settings under `request.sslConfig`.
- For mutual TLS, set `clientCertificateMode: 'explicit'` and `sslClientCertificateId` under `sslConfig`; never embed certificate secrets in a check file.
- Use the exported `TlsVersion`, `CipherSuite`, and `SignatureAlgorithm` constants to avoid invalid assertion values.

## Traceroute monitors

Use `TracerouteMonitor` for path latency, hop-count, and packet-loss diagnostics. The request `url` is a hostname without a scheme or port.

```typescript
import {
  TracerouteAssertionBuilder,
  TracerouteMonitor,
} from 'checkly/constructs'

new TracerouteMonitor('network-path', {
  name: 'Network Path',
  degradedResponseTime: 10000,
  maxResponseTime: 20000,
  request: {
    url: 'example.com',
    protocol: 'TCP',
    port: 443,
    maxHops: 30,
    maxUnknownHops: 15,
    ptrLookup: true,
    assertions: [
      TracerouteAssertionBuilder.responseTime('avg').lessThan(1000),
      TracerouteAssertionBuilder.hopCount().lessThan(20),
      TracerouteAssertionBuilder.packetLoss().lessThan(10),
    ],
  },
})
```

- `protocol` accepts `TCP` (default), `UDP`, `ICMP`, or `SCTP`. If `port` is omitted, the backend defaults to 443 for TCP and 33434 for UDP/SCTP; omit `port` for ICMP.
- `responseTime()` accepts `avg` (default), `min`, `max`, or `stdDev`.
- `hopCount()` and `packetLoss()` do not take a property.

## Validate and deploy

```bash
npx checkly test
npx checkly deploy
```

`retryStrategy`, `runParallel`, and higher frequencies are plan-gated for uptime monitors. Confirm the account's `UPTIME_CHECKS_*` entitlements before adding them; omit unavailable properties.

## Related skills

- See `checkly-checks` for API and browser checks plus deployed result inspection
- See `checkly-groups` for organizing monitors
- See `checkly-test` for local and Checkly-runtime validation
- See `checkly-deploy` for deployment safety
