# Curator for Elasticsearch - Integrated with Logstash

Curator 7.0.1 scheduler for automated index lifecycle management. Integrated directly into the `abo-logstash` app to share the same Elasticsearch connection.

## Dynamic Configuration

Curator automatically parses `$SCALINGO_ELASTICSEARCH_URL` to extract:
- **ELASTICSEARCH_HOST**: hostname
- **ELASTICSEARCH_PORT**: port
- **ELASTICSEARCH_USER**: username
- **ELASTICSEARCH_PASSWORD**: password

## Configuration

The scheduler uses these environment variables:
- `LOGS_RETENTION_DAYS`: retention period in days (default: 10)
- `LOGS_INDICES_PREFIX`: index prefix to clean (default: logs-)

## Deployment

Already integrated in `abo-logstash`:

1. **Set environment variables:**
   ```bash
   scalingo --region osc-fr1 --app abo-logstash env-set \
     LOGS_RETENTION_DAYS=10 \
     LOGS_INDICES_PREFIX=unicorns-
   ```

2. **Deploy:**
   ```bash
   make deploy SERVICE=abo-logstash SCALINGO_REGION=osc-fr1
   ```

3. **Configure Scheduler** (Scalingo dashboard):
   - Add scheduler that runs daily at 03:00 and 15:00 UTC
   - Command: `bash /app/curator/bin/start.sh`

## Scheduler

Runs via Scalingo Scheduler to clean old log indices matching the configured prefix and retention period.
