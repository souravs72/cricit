#!/usr/bin/env bash
# Install CRICIT on an Oracle Cloud Always Free Ampere VM.
# Run as root on Ubuntu 22.04/24.04 after the repo is at /opt/cricit.
set -euo pipefail

ROOT=/opt/cricit
COMPOSE_FILE="${ROOT}/infra/docker-compose.oci.yml"
ENV_FILE="${ROOT}/.env"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo bash ${ROOT}/infra/oci/bootstrap.sh" >&2
  exit 1
fi
if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "Repo missing at ${ROOT}. From your laptop: make oci-sync host=ubuntu@YOUR_IP" >&2
  exit 1
fi

mem_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo)
if [[ "${mem_kb}" -lt 3000000 ]]; then
  echo "Need at least 4 GB RAM. Use VM.Standard.A1.Flex (2 OCPU / 12 GB or 4 OCPU / 24 GB)." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io docker-compose-v2 rsync curl iptables-persistent openssl python3
systemctl enable --now docker

if ! grep -q '/swapfile' /etc/fstab && [[ ! -f /swapfile ]]; then
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null \
  || iptables -I INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null \
  || iptables -I INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
netfilter-persistent save >/dev/null 2>&1 || true
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q 'Status: active'; then
  ufw allow 80/tcp
  ufw allow 443/tcp
fi

public_ip="${CRICIT_PUBLIC_IP:-}"
if [[ -z "${public_ip}" ]]; then
  public_ip=$(curl -4 -fsS --max-time 8 https://ifconfig.me || true)
fi
if [[ -z "${public_ip}" ]]; then
  public_ip=$(curl -4 -fsS --max-time 8 -H "Authorization: Bearer Oracle" \
    http://169.254.169.254/opc/v2/vnics/ | python3 -c "import sys,json; print(json.load(sys.stdin)[0].get('publicIp',''))" 2>/dev/null || true)
fi
if [[ -z "${public_ip}" ]]; then
  echo "Could not detect public IP. Export CRICIT_PUBLIC_IP=x.x.x.x and re-run." >&2
  exit 1
fi

ip_dashed=${public_ip//./-}
api_host="${CRICIT_API_HOST:-api.${ip_dashed}.sslip.io}"
admin_host="${CRICIT_ADMIN_HOST:-admin.${ip_dashed}.sslip.io}"
tls_email="${CRICIT_TLS_EMAIL:-ops@${admin_host}}"

pem_oneline() {
  python3 -c 'from pathlib import Path; print(Path("'"$1"'").read_text().strip().replace("\n", "\\n"))'
}

if [[ ! -f "${ENV_FILE}" ]]; then
  umask 077
  tmp=$(mktemp -d)
  trap 'rm -rf "${tmp}"' EXIT
  openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "${tmp}/priv.pem" >/dev/null 2>&1
  openssl pkey -in "${tmp}/priv.pem" -pubout -out "${tmp}/pub.pem" >/dev/null 2>&1
  pg_pass=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)
  dummy_sa=$(printf '%s' '{"type":"service_account","project_id":"not-configured"}' | base64 -w0)

  cat > "${ENV_FILE}" <<EOF
ENV=production
LOG_LEVEL=INFO
POSTGRES_USER=cricit
POSTGRES_PASSWORD=${pg_pass}
POSTGRES_DB=cricit
DATABASE_URL=postgresql+asyncpg://cricit:${pg_pass}@postgres:5432/cricit
REDIS_URL=redis://redis:6379/0
JWT_KEY_ID=k1
JWT_PRIVATE_KEY="$(pem_oneline "${tmp}/priv.pem")"
JWT_PUBLIC_KEYS="k1=$(pem_oneline "${tmp}/pub.pem")"
FIREBASE_PROJECT_ID=not-configured
FIREBASE_CREDENTIALS_JSON=${dummy_sa}
LLM_PROVIDER=anthropic
LLM_API_KEY=not-configured
LLM_MODEL=
SENTRY_DSN=https://publickey@127.0.0.1/1
ADMIN_ORIGIN=https://${admin_host}
API_BASE_URL=http://api:8000
CRICIT_API_HOST=${api_host}
CRICIT_ADMIN_HOST=${admin_host}
CRICIT_TLS_EMAIL=${tls_email}
CRICIT_PUBLIC_IP=${public_ip}
EOF
  chmod 600 "${ENV_FILE}"
  rm -rf "${tmp}"
  trap - EXIT
  echo "Wrote ${ENV_FILE} (secrets not printed)."
else
  echo "Keeping existing ${ENV_FILE}."
  api_host=$(awk -F= '/^CRICIT_API_HOST=/{print substr($0,index($0,"=")+1)}' "${ENV_FILE}")
  admin_host=$(awk -F= '/^CRICIT_ADMIN_HOST=/{print substr($0,index($0,"=")+1)}' "${ENV_FILE}")
fi

cd "${ROOT}"
export DOCKER_BUILDKIT=1
echo "Building images (admin Next.js on ARM can take 10–20 minutes)..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d --build

echo "Waiting for API /ready..."
for _ in $(seq 1 60); do
  if curl -fsS --max-time 3 "https://${api_host}/ready" >/dev/null 2>&1 \
    || docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" exec -T api \
         python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/ready')" >/dev/null 2>&1; then
    echo "API is ready."
    break
  fi
  sleep 5
done

if [[ "${CRICIT_SEED:-1}" == "1" ]]; then
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" exec -T \
    -e SEED_CREDS=/tmp/seed-credentials \
    api python scripts/seed.py | tee /tmp/cricit-seed.out
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" exec -T api \
    cat /tmp/seed-credentials > "${ROOT}/.seed-credentials" 2>/dev/null || true
  chmod 600 "${ROOT}/.seed-credentials" 2>/dev/null || true
fi

cat <<EOF

CRICIT is up.

  Admin:  https://${admin_host}
  API:    https://${api_host}/ready
  Login:  sudo cat ${ROOT}/.seed-credentials

Point the Flutter app at https://${api_host}
If the admin cookie login fails, wait a minute for Let's Encrypt, then hard-refresh.
EOF
