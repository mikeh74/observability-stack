# Copilot Instructions for Observability Stack

## Project Overview

This repository provides a complete, production-ready observability stack using Docker Compose. It implements the three pillars of observability: logs (Loki), metrics (Prometheus), and traces (Tempo), with Grafana as the central visualization platform.

## Architecture

The stack consists of these key components:
- **Grafana** (port 3000): Unified visualization and dashboards
- **Loki** (port 3100): Log aggregation and querying
- **Prometheus** (port 9090): Metrics collection and storage
- **Tempo** (port 3200): Distributed tracing backend
- **Promtail**: Docker container log collection
- **Fluentd** (port 24224): Flexible log routing and processing
- **Fluent Bit**: Lightweight log forwarding for Apache logs

## Key Technologies

- Docker Compose for orchestration
- YAML for configuration files
- Makefile for developer convenience commands
- pre-commit hooks for code quality

## Development Workflow

### Essential Commands

Use the Makefile for common tasks:
- `make up` - Start all services
- `make down` - Stop all services
- `make restart` - Restart all services
- `make logs` - Follow logs from all services
- `make health` - Check health status of all services
- `make clean` - Stop and remove all containers and volumes
- `make validate` - Validate docker-compose.yml syntax
- `make pre-commit` - Run pre-commit checks on all files

### Testing Changes

1. Always validate docker-compose.yml: `make validate`
2. Start services and check health: `make up && make health`
3. Check logs for errors: `make logs` or service-specific logs
4. Run pre-commit checks before committing: `make pre-commit`

### Building and Running

- The stack uses pre-built images from Docker Hub (Grafana, Prometheus, Loki, Tempo)
- Only Fluentd requires a custom build from `fluentd/Dockerfile`
- Use `make rebuild` to rebuild and restart services after config changes

## Code Style and Conventions

### YAML Files

- Use 2-space indentation
- Keep line length under 120 characters
- Follow yamllint rules (configured in .pre-commit-config.yaml)
- Use `--unsafe` flag for YAML checks to allow custom docker-compose tags

### Configuration Files

- All configuration files are mounted read-only (`:ro`) in containers
- Store configuration at repository root or in service-specific directories
- Use environment variables for secrets (see `.env.example`)

### Docker Compose

- Use specific version tags for images to ensure reproducibility and stability
- Exception: fluent-bit currently uses `latest` tag (consider pinning to specific version for production)
- Define explicit container names for easier debugging
- Use volumes for persistent data
- Document port mappings clearly

### Makefile

- Use `.PHONY` targets for all commands
- Include `## description` comments for help output
- Ensure commands work with both `docker compose` (v2) and legacy syntax

## Configuration Management

### Data Persistence

Volumes for persistent data:
- `grafana_data`: Grafana settings and dashboards
- `loki_data`: Log data
- `prometheus_data`: Metrics data
- `fluentd_data`: Fluentd logs

### Environment Variables

Optional environment variables (via `.env` file):
- `GF_SECURITY_ADMIN_USER`: Grafana admin username (default: admin)
- `GF_SECURITY_ADMIN_PASSWORD`: Grafana admin password (default: admin)

### Service Configuration Files

- `prometheus.yml`: Prometheus scrape configuration
- `loki-config.yaml`: Loki server configuration
- `promtail-config.yml`: Promtail log collection rules
- `tempo-config.yaml`: Tempo tracing configuration
- `fluent-bit/fluent-bit.conf`: Fluent Bit configuration
- `fluent-bit/parsers.conf`: Log parsing rules
- `fluentd/fluent.conf`: Fluentd routing configuration

## Pre-commit Hooks

The repository uses pre-commit hooks for code quality:
- Trailing whitespace removal
- End-of-file fixing
- YAML validation (with docker-compose support)
- JSON validation
- Large file checks (max 1000KB)
- Merge conflict detection
- Mixed line ending detection
- yamllint for YAML linting
- Prettier for JSON/YAML/Markdown formatting

Install hooks: `make install` or `make pre-commit-install`
Update hooks: `make pre-commit-update`
Run manually: `make pre-commit`

## Adding New Features

### Adding a New Service

1. Add service definition to `docker-compose.yml`
2. Create configuration files if needed
3. Update README.md with service information
4. Add service-specific log command to Makefile
5. Update health check in Makefile if service has health endpoint
6. Test with `make validate` and `make up`

### Adding New Configuration

1. Create configuration file in appropriate directory
2. Mount as read-only volume in docker-compose.yml
3. Document in README.md
4. Validate YAML syntax if applicable
5. Test changes with `make restart`

### Modifying Grafana Datasources or Dashboards

- Datasources: Edit `grafana/provisioning/datasources/datasource.yml`
- Dashboards: Add/modify JSON files in `grafana/dashboards/`
- Dashboard provisioning config: `grafana/provisioning/dashboards/dashboards.yml`

## Common Patterns

### Service Dependencies

- Use `depends_on` in docker-compose.yml for service startup order
- Grafana depends on prometheus, loki, and tempo
- Fluentd depends on loki
- Fluent-bit depends on fluentd

### Volume Mounts

- Configuration files: Mount as `:ro` (read-only)
- Data directories: Mount as read-write volumes
- Host paths: Use for Docker socket or host logs

### Port Mapping

- Follow the pattern: `"host_port:container_port"`
- Document all exposed ports in README.md

## Troubleshooting

### Services Not Starting

1. Check logs: `docker compose logs <service-name>`
2. Verify configuration: `make validate`
3. Check port conflicts: `lsof -i :<port>`
4. Ensure Docker daemon is running

### Configuration Changes Not Applied

1. Restart services: `make restart`
2. If that doesn't work, rebuild: `make rebuild`
3. For volume changes, use `make clean` then `make up`

### Pre-commit Hooks Failing

1. Review error messages from pre-commit
2. Fix issues manually or let pre-commit auto-fix
3. Common issues: trailing whitespace, YAML formatting, line endings

## Security Considerations

- Never commit secrets or passwords to the repository
- Use `.env` file for sensitive environment variables (gitignored)
- Change default Grafana credentials in production
- Review `.gitignore` to ensure sensitive files are excluded
- Use specific version tags for Docker images to avoid supply chain issues

## Documentation Standards

- Keep README.md as the primary user-facing documentation
- Update README.md when adding/changing features
- Use clear section headers and consistent formatting
- Include code examples for common tasks
- Maintain the "Available Commands" section in README.md

## Testing Strategy

Since this is an infrastructure/DevOps project:
- Manual testing is primary validation method
- Use `make health` to verify service health
- Test integrations by sending sample data
- Validate configurations before deploying
- Use pre-commit hooks to catch common issues

## Working with This Repository

When making changes:
1. Understand the scope: Is this a config change, new service, or bugfix?
2. Review existing patterns in similar files
3. Make minimal, focused changes
4. Validate with `make validate` and `make pre-commit`
5. Test locally with `make up` and `make health`
6. Check service logs for errors
7. Update documentation if adding/changing features
8. Ensure changes are production-ready

## Performance Considerations

- Monitor resource usage: `docker compose ps` and `docker stats`
- Configure retention policies for Loki and Prometheus in production
- Use appropriate resource limits in docker-compose.yml for production
- Consider data volume growth for persistent storage

## Integration Points

### Sending Logs to Loki

- Via Promtail: Automatic for Docker containers
- Via Fluentd: Configure apps to send to `localhost:24224`
- Direct HTTP: POST to `http://localhost:3100/loki/api/v1/push`

### Collecting Metrics with Prometheus

- Add scrape targets to `prometheus.yml`
- Use `host.docker.internal` to access host services
- Restart Prometheus after config changes

### Sending Traces to Tempo

- Configure OTLP endpoint: `http://localhost:3200`
- Use OpenTelemetry SDKs in applications
