# Observability Bootstrap Pack — Grafana / Loki / Prometheus / Tempo (Docker Compose)

This repo contains a repeatable, version-controlled bootstrap for a self-hosted observability stack using Docker Compose. It provides logs (Loki + Promtail), metrics (Prometheus), traces (Tempo + OpenTelemetry), and Grafana for visualization. Everything is config-as-code and designed to be Git-friendly.

---

## Repo layout

```
observability-bootstrap/
├── docker-compose.yml
├── loki-config.yaml
├── promtail-config.yml
├── prometheus.yml
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── datasource.yml
│   │   └── dashboards/
│   │       └── dashboards.yml
│   └── dashboards/
│       └── app-overview.json
├── tempo-config.yaml
├── django-otel/
│   ├── requirements.txt
│   └── otel_instrumentation_example.py
└── README.md
```

---

## How to use

1. Clone the repo.
2. (Optional) Edit `promtail-config.yml` and `prometheus.yml` for targets you want to scrape.
3. `docker compose up -d`
4. Open Grafana at `http://localhost:3000` (default admin/admin — please change in production).

---

## Files (copy these into files in your repo)

### `docker-compose.yml`

```yaml
version: "3.9"

services:
  grafana:
    image: grafana/grafana:11.0.0
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_SERVER_ROOT_URL=%(protocol)s://%(domain)s:%(http_port)s
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
      - loki
      - tempo

  loki:
    image: grafana/loki:2.9.0
    container_name: loki
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - ./loki-config.yaml:/etc/loki/local-config.yaml:ro
      - loki_data:/loki
    ports:
      - "3100:3100"

  promtail:
    image: grafana/promtail:2.9.0
    container_name: promtail
    command: -config.file=/etc/promtail/config.yml
    volumes:
      - ./promtail-config.yml:/etc/promtail/config.yml:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock

  prometheus:
    image: prom/prometheus:v2.52.0
    container_name: prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"

  tempo:
    image: grafana/tempo:2.5.0
    container_name: tempo
    command: -config.file=/etc/tempo/tempo.yaml
    volumes:
      - ./tempo-config.yaml:/etc/tempo/tempo.yaml:ro
    ports:
      - "3200:3200"

volumes:
  loki_data:
  grafana_data:
  prometheus_data:
```

---

### `loki-config.yaml`

```yaml
auth_enabled: false
server:
  http_listen_port: 3100
  http_grpc_port: 9095

ingester:
  wal:
    enabled: true
  lifecycler:
    ring:
      kvstore:
        store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/cache
  filesystem:
    directory: /loki/chunks

limits_config:
  ingestion_rate_mb: 10
  ingestion_burst_size_mb: 20
  max_streams_per_user: 0

chunk_target_size: 1048576

ruler:
  ring:
    kvstore:
      store: inmemory
```

---

### `promtail-config.yml`

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  - job_name: docker-logs
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
    relabel_configs:
      - source_labels:
          ["__meta_docker_container_label_com_docker_swarm_service_name"]
        target_label: service
      - source_labels: ["__meta_docker_container_name"]
        target_label: container
    pipeline_stages:
      - docker: {}
```

Notes:

- This config tails `/var/log/*log` and the Docker container logs via the Docker socket. Adjust `__path__` or add file-based scraping as needed.

---

### `prometheus.yml`

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  # Example: scrape node_exporter running on host
  - job_name: node_exporter
    static_configs:
      - targets: ["node-exporter:9100"]

  # Add your application metrics endpoints here
```

---

### `tempo-config.yaml`

```yaml
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
        http:

ingester:
  trace_idle_after: 5m

storage:
  trace:
    backend: local
    local:
      path: /tmp/tempo/traces

grpc_server_max_recv_msg_size: 200
```

Notes: In production you should use object storage (S3/GCS) and configure retention.

---

### Grafana provisioning

Create `grafana/provisioning/datasources/datasource.yml`:

```yaml
apiVersion: 1
deleteDatasources:
  - name: Prometheus
    orgId: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false

  - name: Tempo
    type: tempo
    access: proxy
    url: http://tempo:3200
    editable: false
```

Create `grafana/provisioning/dashboards/dashboards.yml`:

```yaml
apiVersion: 1
providers:
  - name: "default"
    orgId: 1
    folder: ""
    type: file
    options:
      path: /var/lib/grafana/dashboards
```

Place `grafana/dashboards/app-overview.json` — a simple JSON dashboard (example below).

---

### `grafana/dashboards/app-overview.json` (simple example)

```json
{
  "annotations": { "list": [] },
  "panels": [
    {
      "type": "graph",
      "title": "HTTP requests (example)",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "sum(rate(http_requests_total[1m])) by (job)",
          "legendFormat": "{{job}}"
        }
      ]
    },
    {
      "type": "logs",
      "title": "Recent logs",
      "datasource": "Loki",
      "targets": [
        {
          "expr": "{job=\"varlogs\"}",
          "refId": "A"
        }
      ]
    }
  ],
  "schemaVersion": 36,
  "title": "App Overview"
}
```

(Export a dashboard from Grafana after you connect datasources to produce richer JSON.)

---

## Django OpenTelemetry example

Create `django-otel/requirements.txt`:

```
opentelemetry-api
opentelemetry-sdk
opentelemetry-exporter-otlp
opentelemetry-instrumentation-django
requests
```

Create `django-otel/otel_instrumentation_example.py`:

```python
# Run this early in your Django startup (e.g., in manage.py before execute_from_command_line)
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.django import DjangoInstrumentor

resource = Resource.create({
    "service.name": "my-django-app"
})

provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="http://tempo:4317", insecure=True))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

DjangoInstrumentor().instrument()

# Now Django requests/DB calls are auto-instrumented and will be sent to Tempo
```

Notes:

- OTLP default gRPC port is 4317. The example uses `endpoint="http://tempo:4317"` which works when services share Docker network and Tempo accepts OTLP. Adjust in production.

---

## Security & Production notes

- Change Grafana admin password and use proper secrets management (don’t keep secrets in Git if private).
- Use object storage for Loki and Tempo in production (S3/GCS) and configure retention.
- Set resource limits, monitoring, backups for Prometheus data and Loki indexes.
- Consider running services as managed or behind systemd / container orchestrator for resiliency.

---

## Helpful commands

- Start: `docker compose up -d`
- Stop: `docker compose down`
- Rebuild (if you modify images): `docker compose up -d --build`
- Tail logs: `docker compose logs -f grafana loki prometheus promtail tempo`

---

## Next steps I can do for you

- Produce an opinionated `docker-compose.override.yml` that runs node_exporter and a tiny sample Django app container so you can see metrics/logs/traces end-to-end.
- Generate a richer Grafana dashboard (JSON) for HTTP latency, error rate, and log-to-trace linking.
- Add Docker healthchecks and resource limits for each service.

---
