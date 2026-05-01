#!/usr/bin/env bash
# Deploy the latest code from the develop branch to the staging server.
# Called by GitHub Actions via SSH, or manually: ssh deploy@<ip> /opt/tatl/infra/scripts/deploy.sh
set -euo pipefail

APP_ROOT="/opt/tatl"
PORTAL="${APP_ROOT}/apps/portal"
ENV_FILE="${APP_ROOT}/.env.production"

echo "── Pulling latest from develop ──"
cd "$APP_ROOT"
git fetch origin develop
git reset --hard origin/develop

# When called from GitHub Actions, secrets are forwarded as env vars.
# Write them to .env.production so the server always stays in sync.
if [[ -n "${RAILS_MASTER_KEY:-}" ]]; then
  echo "── Writing .env.production from secrets ──"
  cat > "$ENV_FILE" <<EOF
RAILS_ENV=production
RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
TATL_DB_HOST=${TATL_DB_HOST:-localhost}
TATL_DB_PORT=5432
TATL_DB_USERNAME=tatl
TATL_DB_PASSWORD=${TATL_DB_PASSWORD:-}
TATL_DB_NAME=tatl_staging
SOLID_QUEUE_IN_PUMA=true
WEB_CONCURRENCY=2
RAILS_MAX_THREADS=5
SECRET_KEY_BASE=${SECRET_KEY_BASE:-}
APP_HOST=${APP_HOST:-localhost}
SENDGRID_API_KEY=${SENDGRID_API_KEY:-}
TATL_MAILER_SENDER=${TATL_MAILER_SENDER:-no-reply@tatl.local}
OIDC_ISSUER=${OIDC_ISSUER:-http://localhost:3000}
OIDC_SIGNING_KEY=${OIDC_SIGNING_KEY:-}
EOF
  chmod 600 "$ENV_FILE"
fi

set -a
source "$ENV_FILE"
set +a
export RAILS_ENV=production

echo "── Installing gems ──"
cd "$PORTAL"
bundle config set --local deployment true
bundle config set --local without "development test"
bundle install --jobs 4 --quiet

echo "── Running migrations ──"
bin/rails db:migrate

echo "── Precompiling assets ──"
bin/rails assets:precompile

echo "── Reloading nginx ──"
if command -v nginx &>/dev/null && [[ -f /etc/ssl/cloudflare/origin.pem ]]; then
  sudo nginx -t && sudo systemctl reload nginx
else
  echo "nginx not yet configured (cert missing or nginx not installed) – skipping reload"
fi

echo "── Restarting services ──"
sudo systemctl restart tatl-web
sudo systemctl restart tatl-worker

echo "── Health check ──"
sleep 8
if curl -sf http://localhost:3000/up > /dev/null; then
  echo "Deploy complete - health check passed"
else
  echo "ERROR: Health check failed!"
  sudo journalctl -u tatl-web --no-pager -n 30
  exit 1
fi
