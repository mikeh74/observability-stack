# Observability Stack

A complete, production-ready observability stack using Docker Compose. This repository provides a unified solution for logs, metrics, and traces with Grafana as the central visualization platform.

## 🎯 Intention

This setup is designed to provide:

- **Complete Observability**: The three pillars of observability (logs, metrics, traces) in a single stack
- **Production-Ready**: Configuration-as-code approach with best practices baked in
- **Easy Deployment**: One-command setup using Docker Compose
- **Flexible Log Collection**: Multiple log shippers (Promtail, Fluentd, Fluent Bit) for different use cases
- **Pre-configured Integration**: All components pre-wired and ready to receive data
- **Developer-Friendly**: Quick local development setup with sensible defaults

### Components

| Component      | Purpose                                  | Port  |
| -------------- | ---------------------------------------- | ----- |
| **Grafana**    | Unified visualization and dashboards     | 3000  |
| **Loki**       | Log aggregation and querying             | 3100  |
| **Prometheus** | Metrics collection and storage           | 9090  |
| **Tempo**      | Distributed tracing backend              | 3200  |
| **Promtail**   | Docker container log collection          | -     |
| **Fluentd**    | Flexible log routing and processing      | 24224 |
| **Fluent Bit** | Lightweight log forwarding (Apache logs) | -     |

## 🚀 Getting Started

### Prerequisites

- Docker (20.10+)
- Docker Compose (v2.0+)
- Make (optional, for convenience commands)

### Quick Start

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd observability-stack
   ```

2. **Set environment variables** (optional)

   Create a `.env` file for custom Grafana credentials:

   ```bash
   GF_SECURITY_ADMIN_USER=admin
   GF_SECURITY_ADMIN_PASSWORD=your-secure-password
   ```

3. **Start the stack**

   ```bash
   make up
   # or
   docker compose up -d
   ```

4. **Verify services are running**

   ```bash
   make health
   # or
   docker compose ps
   ```

5. **Access Grafana**

   Open http://localhost:3000 in your browser

   - Default credentials: `admin/admin` (change on first login)
   - Datasources are pre-configured for Loki, Prometheus, and Tempo
   - Sample dashboards are available in the Dashboards menu

### Available Commands

Use `make help` to see all available commands:

```bash
make up              # Start all services
make down            # Stop all services
make restart         # Restart all services
make logs            # Follow logs from all services
make logs-grafana    # Follow Grafana logs only
make health          # Check health status of all services
make clean           # Stop and remove all containers and volumes
make rebuild         # Rebuild and restart all services
make validate        # Validate docker-compose.yml syntax
```

## 📁 Repository Structure

```
observability-stack/
├── docker-compose.yml              # Main orchestration file
├── Makefile                        # Convenience commands
├── prometheus.yml                  # Prometheus scrape configuration
├── loki-config.yaml               # Loki server configuration
├── promtail-config.yml            # Promtail log collection rules
├── tempo-config.yaml              # Tempo tracing configuration
├── fluent-bit/
│   ├── fluent-bit.conf           # Fluent Bit configuration
│   └── parsers.conf              # Log parsing rules
├── fluentd/
│   ├── Dockerfile                # Custom Fluentd image
│   └── fluent.conf               # Fluentd routing configuration
└── grafana/
    ├── provisioning/
    │   ├── datasources/
    │   │   └── datasource.yml    # Auto-configured datasources
    │   └── dashboards/
    │       └── dashboards.yml    # Dashboard provisioning
    └── dashboards/
        └── app-overview.json     # Sample dashboard

```

## 🔧 Configuration

### Sending Logs to Loki

**Via Promtail** (for Docker containers):
Promtail automatically collects logs from all Docker containers. No additional configuration needed.

**Via Fluentd** (for application logs):
Configure your application to send logs to `localhost:24224`:

```ruby
<source>
  @type forward
  port 24224
</source>
```

**Direct HTTP API**:

```bash
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{"streams":[{"stream":{"service":"test"},"values":[["'$(date +%s%N)'","test log message"]]}]}'
```

### Collecting Metrics with Prometheus

Add scrape targets to `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: "my-app"
    static_configs:
      - targets: ["host.docker.internal:8080"]
```

Then restart Prometheus:

```bash
make restart
```

### Sending Traces to Tempo

Configure your application to send traces to Tempo's OTLP endpoint:

```
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:3200
```

## 📊 Using Grafana

1. **Explore Logs**: Navigate to Explore → Select Loki datasource
2. **Query Metrics**: Navigate to Explore → Select Prometheus datasource
3. **View Traces**: Navigate to Explore → Select Tempo datasource
4. **Create Dashboards**: Use the pre-configured datasources to build custom dashboards

## 🛠️ Troubleshooting

**Services not starting?**

```bash
docker compose logs <service-name>
```

**Can't access Grafana?**

- Ensure port 3000 is not in use: `lsof -i :3000`
- Check Grafana logs: `make logs-grafana`

**No logs appearing in Loki?**

- Verify Promtail is running: `docker compose ps promtail`
- Check Promtail logs: `docker compose logs promtail`
- Ensure Docker socket is accessible

**Prometheus not scraping targets?**

- Check targets in Prometheus UI: http://localhost:9090/targets
- Verify network connectivity from Prometheus container
- Review `prometheus.yml` configuration

## 📝 Next Steps

- Customize `grafana/dashboards/` with your own dashboards
- Configure alerting rules in Prometheus
- Add more scrape targets for your applications
- Set up retention policies in Loki and Prometheus
- Configure authentication and security for production use

## 🔒 Production Considerations

- Change default Grafana credentials
- Enable authentication for all services
- Configure proper retention policies
- Set up backup strategies for persistent data
- Use reverse proxy with SSL/TLS
- Implement proper network segmentation
- Configure resource limits in docker-compose.yml

---
