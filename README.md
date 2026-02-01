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

| Component      | Purpose                                  | Port         |
| -------------- | ---------------------------------------- | ------------ |
| **Nginx**      | Reverse proxy with SSL/TLS termination   | 80, 443      |
| **Grafana**    | Unified visualization and dashboards     | 3000*        |
| **Loki**       | Log aggregation and querying             | 3100*        |
| **Prometheus** | Metrics collection and storage           | 9090*        |
| **Tempo**      | Distributed tracing backend              | 3200*        |
| **Promtail**   | Docker container log collection          | -            |
| **Fluentd**    | Flexible log routing and processing      | 24224        |
| **Fluent Bit** | Lightweight log forwarding (Apache logs) | -            |
| **Certbot**    | Let's Encrypt certificate management     | -            |

*Ports are exposed internally and accessible via nginx reverse proxy on ports 80/443

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

   Create a `.env` file for custom configuration:

   ```bash
   GF_SECURITY_ADMIN_USER=admin
   GF_SECURITY_ADMIN_PASSWORD=your-secure-password
   DOMAIN=localhost  # Change to your domain for production
   ```

3. **Generate SSL certificates**

   For development with self-signed certificates:

   ```bash
   make generate-self-signed-certs
   ```

   For production with Let's Encrypt, see [SSL/TLS Setup](#ssl-tls-setup) section below.

4. **Start the stack**

   ```bash
   make up
   # or
   docker compose up -d
   ```

5. **Verify services are running**

   ```bash
   make health
   # or
   docker compose ps
   ```

6. **Access services via nginx**

   Open https://localhost in your browser (accept the self-signed certificate warning)

   - **Grafana**: https://localhost/grafana/
   - **Prometheus**: https://localhost/prometheus/
   - **Loki**: https://localhost/loki/
   - **Tempo**: https://localhost/tempo/

   Default Grafana credentials: `admin/admin` (change on first login)

### Available Commands

Use `make help` to see all available commands:

```bash
make up                          # Start all services
make down                        # Stop all services
make restart                     # Restart all services
make logs                        # Follow logs from all services
make logs-grafana                # Follow Grafana logs only
make logs-nginx                  # Follow nginx logs only
make health                      # Check health status of all services
make clean                       # Stop and remove all containers and volumes
make rebuild                     # Rebuild and restart all services
make validate                    # Validate docker-compose.yml syntax
make generate-self-signed-certs  # Generate self-signed SSL certificates
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
├── nginx/
│   ├── nginx.conf                 # Main nginx configuration
│   ├── ssl-params.conf            # SSL/TLS security settings
│   ├── docker-entrypoint.sh       # Entrypoint script for config substitution
│   ├── conf.d/
│   │   └── default.conf.template  # Reverse proxy configuration template
│   ├── ssl/                       # SSL certificates directory
│   └── README.md                  # Nginx configuration documentation
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

## 🔐 SSL/TLS Setup

The observability stack includes nginx as a reverse proxy with SSL/TLS support. You have two options:

### Option 1: Self-Signed Certificates (Development)

For local development, generate self-signed certificates:

```bash
make generate-self-signed-certs
```

This creates:
- `nginx/ssl/cert.pem` - SSL certificate
- `nginx/ssl/key.pem` - Private key

**Note**: Browsers will show a security warning for self-signed certificates. Click "Advanced" and proceed to accept the certificate for development purposes.

### Option 2: Let's Encrypt (Production)

For production deployments with a valid domain:

1. **Configure your domain**

   Update the `.env` file:
   ```bash
   DOMAIN=your-domain.com
   ```

2. **Ensure DNS is configured**

   Point your domain's A record to your server's IP address.

3. **Start the stack**

   ```bash
   make up
   ```

4. **Obtain Let's Encrypt certificate**

   ```bash
   docker compose run --rm certbot certonly --webroot \
     --webroot-path=/var/www/certbot \
     --email your-email@example.com \
     --agree-tos \
     --no-eff-email \
     -d your-domain.com
   ```

5. **Update nginx configuration**

   Edit `nginx/conf.d/default.conf.template` to use Let's Encrypt certificates:

   ```nginx
   ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
   ```

6. **Restart nginx**

   ```bash
   docker compose restart nginx
   ```

7. **Set up automatic renewal**

   The certbot container automatically renews certificates daily. To ensure nginx reloads after renewal, add a cron job:

   ```bash
   # Reload nginx configuration daily at 2am
   0 2 * * * cd /path/to/observability-stack && docker compose exec nginx nginx -s reload
   ```

### Accessing Services with SSL/TLS

Once SSL/TLS is configured:

- All services are accessible via HTTPS on port 443
- HTTP requests on port 80 are automatically redirected to HTTPS
- Access services at:
  - Grafana: `https://your-domain/grafana/`
  - Prometheus: `https://your-domain/prometheus/`
  - Loki: `https://your-domain/loki/`
  - Tempo: `https://your-domain/tempo/`

## 📝 Next Steps

- Customize `grafana/dashboards/` with your own dashboards
- Configure alerting rules in Prometheus
- Add more scrape targets for your applications
- Set up retention policies in Loki and Prometheus
- Configure authentication and security for production use

## 🔒 Production Considerations

- Change default Grafana credentials
- Enable authentication for all services (nginx basic auth or OAuth)
- Configure proper retention policies
- Set up backup strategies for persistent data
- Use Let's Encrypt certificates for SSL/TLS (see SSL/TLS Setup section)
- Implement proper network segmentation
- Configure resource limits in docker-compose.yml
- Set up firewall rules to restrict access to ports 80/443 only
- Enable nginx access logs monitoring
- Configure fail2ban or similar for brute-force protection

---
