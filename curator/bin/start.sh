#!/bin/bash
set -e

CURATOR_HOME="${CURATOR_HOME:-.}"
LOGS_RETENTION_DAYS="${LOGS_RETENTION_DAYS:-10}"
LOGS_INDICES_PREFIX="${LOGS_INDICES_PREFIX:-logs-}"

# Parse SCALINGO_ELASTICSEARCH_URL if available
if [ -n "$SCALINGO_ELASTICSEARCH_URL" ]; then
  echo "Parsing SCALINGO_ELASTICSEARCH_URL..."
  # URL format: http://user:pass@host:port
  if [[ $SCALINGO_ELASTICSEARCH_URL =~ ^http://([^:]+):([^@]+)@([^:]+):([0-9]+)$ ]]; then
    ELASTICSEARCH_USER="${BASH_REMATCH[1]}"
    ELASTICSEARCH_PASSWORD="${BASH_REMATCH[2]}"
    ELASTICSEARCH_HOST="${BASH_REMATCH[3]}"
    ELASTICSEARCH_PORT="${BASH_REMATCH[4]}"
  fi
fi

# Use provided variables if not parsed from URL
ELASTICSEARCH_HOST="${ELASTICSEARCH_HOST:?Error: ELASTICSEARCH_HOST not set}"
ELASTICSEARCH_PORT="${ELASTICSEARCH_PORT:?Error: ELASTICSEARCH_PORT not set}"
ELASTICSEARCH_USER="${ELASTICSEARCH_USER:?Error: ELASTICSEARCH_USER not set}"
ELASTICSEARCH_PASSWORD="${ELASTICSEARCH_PASSWORD:?Error: ELASTICSEARCH_PASSWORD not set}"

echo "Generating curator configuration..."

# Create curator.yml
cat > "$CURATOR_HOME/curator.yml" <<EOF
---
client:
  hosts:
    - $ELASTICSEARCH_HOST
  port: $ELASTICSEARCH_PORT
  http_auth: $ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD
  use_ssl: False
  ssl_no_validate: True
  timeout: 30

logging:
  loglevel: INFO
  logfile:
  logformat: default
EOF

# Create log-clean.yml
cat > "$CURATOR_HOME/log-clean.yml" <<EOF
actions:
  1:
    action: delete_indices
    description: Delete old log indices
    options:
      ignore_empty_list: True
      disable_action: False
    filters:
      - filtertype: pattern
        kind: prefix
        value: $LOGS_INDICES_PREFIX
      - filtertype: age
        source: name
        direction: older
        timestring: '%Y.%m.%d'
        unit: days
        unit_count: $LOGS_RETENTION_DAYS
EOF

echo "Running Curator cleanup..."
exec curator --config "$CURATOR_HOME/curator.yml" "$CURATOR_HOME/log-clean.yml"
