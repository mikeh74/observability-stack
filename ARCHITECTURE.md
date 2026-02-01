# Observability Stack Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        External Access                       │
└─────────────────────────────────────────────────────────────┘
                    │ HTTP (80)    │ HTTPS (443)
                    ▼              ▼
            ┌───────────────────────────┐
            │    Nginx Reverse Proxy    │
            │   - SSL/TLS Termination   │
            │   - HTTP → HTTPS Redirect │
            │   - Security Headers      │
            └───────────────────────────┘
                         │
         ┌───────────────┼───────────────┬────────────┐
         │               │               │            │
         ▼               ▼               ▼            ▼
    ┌─────────┐    ┌──────────┐    ┌──────┐    ┌───────┐
    │ Grafana │    │Prometheus│    │ Loki │    │ Tempo │
    │  :3000  │    │  :9090   │    │:3100 │    │ :3200 │
    └─────────┘    └──────────┘    └──────┘    └───────┘
         │               │               │            │
         └───────────────┴───────────────┴────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Log Collection  │
                    │                  │
                    │  - Promtail      │
                    │  - Fluentd       │
                    │  - Fluent Bit    │
                    └──────────────────┘
```

## Service Routes

### HTTPS Endpoints (Port 443)

| Path                  | Backend Service | Purpose                      |
|-----------------------|-----------------|------------------------------|
| `/grafana/`           | grafana:3000    | Visualization & Dashboards   |
| `/prometheus/`        | prometheus:9090 | Metrics & Queries            |
| `/loki/`              | loki:3100       | Log Aggregation              |
| `/tempo/`             | tempo:3200      | Distributed Tracing          |
| `/health`             | nginx           | Health Check                 |
| `/`                   | (redirect)      | → `/grafana/`                |

### HTTP Endpoint (Port 80)

All HTTP requests are redirected to HTTPS (301 redirect).

## SSL/TLS Configuration

### Development Setup
- Self-signed certificates generated via `make generate-self-signed-certs`
- Located in `nginx/ssl/cert.pem` and `nginx/ssl/key.pem`
- Valid for 1 year

### Production Setup
- Let's Encrypt certificates via certbot
- Automatic renewal every 24 hours
- Stored in `certbot_conf` volume
- OCSP stapling enabled

### Security Settings
- **Protocols**: TLS 1.2, TLS 1.3
- **Ciphers**: ECDHE-based ciphers only (no DHE)
- **Headers**:
  - `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
  - `X-Frame-Options: SAMEORIGIN`
  - `X-Content-Type-Options: nosniff`
  - `X-XSS-Protection: 1; mode=block`
  - `Referrer-Policy: no-referrer-when-downgrade`

## Network Flow

1. **Client Request** → Port 80/443
2. **Nginx Processing**:
   - SSL/TLS termination (for HTTPS)
   - Add security headers
   - Route based on path
3. **Backend Service** → Process request internally
4. **Response** → Through nginx to client

## Data Volumes

| Volume Name     | Purpose                          |
|-----------------|----------------------------------|
| `grafana_data`  | Grafana dashboards & settings    |
| `loki_data`     | Loki log storage                 |
| `prometheus_data`| Prometheus metrics storage      |
| `fluentd_data`  | Fluentd buffered logs           |
| `certbot_conf`  | Let's Encrypt certificates      |
| `certbot_www`   | ACME challenge files            |

## Service Dependencies

```
nginx
  ├── depends on: grafana
  ├── depends on: prometheus
  ├── depends on: loki
  └── depends on: tempo

grafana
  ├── depends on: prometheus
  ├── depends on: loki
  └── depends on: tempo

promtail
  └── (monitors all containers)

fluentd
  └── depends on: loki

fluent-bit
  └── depends on: fluentd
```

## Ports Summary

### Exposed to Host
- `80` - HTTP (redirects to HTTPS)
- `443` - HTTPS (all services via reverse proxy)
- `24224` - Fluentd input (TCP/UDP)

### Internal Only
- `3000` - Grafana
- `3100` - Loki
- `3200` - Tempo
- `9090` - Prometheus

## Configuration Files

```
nginx/
├── nginx.conf                 # Main nginx config
├── ssl-params.conf            # SSL/TLS settings
├── docker-entrypoint.sh       # Startup script
├── conf.d/
│   └── default.conf.template  # Reverse proxy config (with env vars)
└── ssl/                       # SSL certificates
    ├── cert.pem               # Certificate (generated)
    └── key.pem                # Private key (generated)
```
