# Nginx Reverse Proxy Configuration

This directory contains the nginx configuration for the observability stack reverse proxy.

## Files

- `nginx.conf` - Main nginx configuration
- `conf.d/default.conf` - Reverse proxy configuration for all services
- `ssl-params.conf` - SSL/TLS security settings
- `ssl/` - Directory for SSL certificates (created at runtime)

## Services Exposed

The nginx reverse proxy exposes the following services:

- `/grafana/` - Grafana dashboard (port 443)
- `/prometheus/` - Prometheus metrics (port 443)
- `/loki/` - Loki log aggregation (port 443)
- `/tempo/` - Tempo tracing (port 443)

## SSL/TLS Setup

### Option 1: Self-Signed Certificates (Development)

Generate self-signed certificates using the provided Makefile target:

```bash
make generate-self-signed-certs
```

This will create:
- `nginx/ssl/cert.pem`
- `nginx/ssl/key.pem`

**Note**: Browsers will show a warning for self-signed certificates. This is expected and safe for development.

### Option 2: Let's Encrypt (Production)

For production use with Let's Encrypt:

1. Set your domain in `.env`:
   ```
   DOMAIN=your-domain.com
   ```

2. Start the stack:
   ```bash
   make up
   ```

3. Obtain Let's Encrypt certificate using certbot:
   ```bash
   docker compose run --rm certbot certonly --webroot \
     --webroot-path=/var/www/certbot \
     --email your-email@example.com \
     --agree-tos \
     --no-eff-email \
     -d your-domain.com
   ```

4. The certificates will be stored in the `certbot/conf` volume and automatically used by nginx.

5. Set up auto-renewal by adding a cron job:
   ```bash
   # Renew certificates daily at 2am
   0 2 * * * cd /path/to/observability-stack && docker compose run --rm certbot renew && docker compose exec nginx nginx -s reload
   ```

## Accessing Services

After starting the stack with nginx:

- **Grafana**: https://your-domain/grafana/
- **Prometheus**: https://your-domain/prometheus/
- **Loki**: https://your-domain/loki/
- **Tempo**: https://your-domain/tempo/

For local development with self-signed certificates:
- **Grafana**: https://localhost/grafana/
- **Prometheus**: https://localhost/prometheus/
- **Loki**: https://localhost/loki/
- **Tempo**: https://localhost/tempo/

## Configuration Notes

- The default configuration redirects HTTP (port 80) to HTTPS (port 443)
- The root path `/` redirects to `/grafana/`
- WebSocket support is enabled for Grafana and Loki
- GZIP compression is enabled for better performance
- Security headers are configured following best practices
