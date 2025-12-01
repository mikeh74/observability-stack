ARG TARGETPLATFORM
FROM fluent/fluentd:v1.17-debian-arm64-1

USER root

# Install dependencies and Loki plugin
RUN apk add --no-cache --update \
    build-base \
    ruby-dev \
 && gem install fluent-plugin-grafana-loki \
 && gem sources --clear-all \
 && apk del build-base ruby-dev \
 && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

USER fluent
