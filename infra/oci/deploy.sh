#!/usr/bin/env bash
# Deploy to server via Git pull and container rebuild.
# Usage: infra/oci/deploy.sh [ubuntu@137.23.51.182]
# Strictly uses GitHub commit -> push -> server pull. No rsync.
set -euo pipefail

HOST="${1:-ubuntu@137.23.51.182}"
KEY="${SSH_KEY:-/home/ascra/.ssh/cricit_oci.key}"

SSH_CMD="ssh -i ${KEY} -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=15 -o ServerAliveCountMax=60"

echo "==> Triggering Git pull and deployment on ${HOST}..."
${SSH_CMD} "${HOST}" 'bash -s' << 'EOF'
  set -euo pipefail
  cd /opt/cricit
  echo "==> Pulling latest changes from GitHub origin/main..."
  git pull origin main
  
  echo "==> Latest deployed commit:"
  git log -1 --oneline

  echo "==> Rebuilding containers if necessary..."
  docker compose --env-file /opt/cricit/.env -f infra/docker-compose.oci.yml up -d --build
  
  echo "==> Deployment successfully finished!"
EOF
