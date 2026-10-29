#!/usr/bin/env bash
# Restore a dump into a scratch database to prove backups work (run the drill monthly).
# Usage: restore.sh cricit-20261020T213000Z.dump
set -euo pipefail

DUMP="${1:?usage: restore.sh <dump file name in r2:cricit-backups/postgres/>}"
COMPOSE_FILE=/opt/cricit/infra/docker-compose.prod.yml
[[ -f /opt/cricit/infra/docker-compose.oci.yml ]] && COMPOSE_FILE=/opt/cricit/infra/docker-compose.oci.yml
COMPOSE=(docker compose --env-file /opt/cricit/.env -f "${COMPOSE_FILE}")

rclone copy "r2:cricit-backups/postgres/${DUMP}" /tmp/
"${COMPOSE[@]}" exec -T postgres \
  sh -c 'dropdb -U "$POSTGRES_USER" --if-exists cricit_restore_check && createdb -U "$POSTGRES_USER" cricit_restore_check'
"${COMPOSE[@]}" exec -T postgres \
  sh -c 'pg_restore -U "$POSTGRES_USER" -d cricit_restore_check --no-owner' < "/tmp/${DUMP}"
"${COMPOSE[@]}" exec -T postgres \
  psql -U "$POSTGRES_USER" -d cricit_restore_check -c "select count(*) as posts from posts;"
echo "Restore check passed for ${DUMP}"
