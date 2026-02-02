#!/bin/sh
# Script to substitute environment variables in nginx config

set -e

# Set default values if not provided
export DOMAIN="${DOMAIN:-localhost}"

echo "Configuring nginx with DOMAIN=${DOMAIN}"

# Use envsubst to substitute variables in the config file
envsubst '${DOMAIN}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Start nginx
exec nginx -g 'daemon off;'
