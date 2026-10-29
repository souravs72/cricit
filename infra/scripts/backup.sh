#!/usr/bin/env bash
# Nightly Postgres backup to Cloudflare R2. Cron: 30 21 * * * (03:00 IST)
# Needs: rclone remote "r2" configured; compose project running.
set -euo pipefail

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
FILE="/var/backups/cricit/cricit-${STAMP}.dump"
mkdir -p /var/backups/cricit

COMPOSE_FILE=/opt/cricit/infra/docker-compose.prod.yml
[[ -f /opt/cricit/infra/docker-compose.oci.yml ]] && COMPOSE_FILE=/opt/cricit/infra/docker-compose.oci.yml

docker compose --env-file /opt/cricit/.env -f "${COMPOSE_FILE}" exec -T postgres \
  sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom' > "${FILE}"

# A dump smaller than 10 KB means something went wrong; fail loudly.
if [ "$(stat -c%s "${FILE}")" -lt 10240 ]; then
  echo "Backup too small: ${FILE}" >&2
  exit 1
fi

rclone copy "${FILE}" "r2:cricit-backups/postgres/"
rclone delete --min-age 14d "r2:cricit-backups/postgres/"
find /var/backups/cricit -name '*.dump' -mtime +2 -delete
echo "Backup uploaded: ${FILE}"
