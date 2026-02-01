ARG TARGETPLATFORM
FROM fluentd:v1.19.1-debian-1.0

USER root

# Install security updates and dependencies
RUN apt-get update && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
    build-essential \
    ruby-dev \
 && gem install fluent-plugin-grafana-loki \
 && gem sources --clear-all \
 && apt-get remove -y build-essential ruby-dev \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

USER fluent
