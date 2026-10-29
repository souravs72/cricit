#!/usr/bin/env bash
# Copy this repo to an Oracle Always Free VM and run bootstrap.
# Usage: infra/oci/sync.sh ubuntu@YOUR_PUBLIC_IP
set -euo pipefail

HOST="${1:?usage: infra/oci/sync.sh ubuntu@YOUR_PUBLIC_IP}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

ssh -o StrictHostKeyChecking=accept-new "${HOST}" \
  'sudo mkdir -p /opt/cricit && sudo chown "$(id -un):$(id -gn)" /opt/cricit'

rsync -az --delete --info=progress2 \
  --exclude '.git/' \
  --exclude '**/node_modules/' \
  --exclude '**/.venv/' \
  --exclude '**/.next/' \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude '.seed-credentials' \
  --exclude 'mobile/' \
  --exclude '**/__pycache__/' \
  --exclude '**/*.pyc' \
  -e ssh \
  "${ROOT}/" "${HOST}:/opt/cricit/"

ssh -t "${HOST}" "sudo bash /opt/cricit/infra/oci/bootstrap.sh"
