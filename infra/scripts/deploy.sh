#!/usr/bin/env bash
# Deploy the latest code from the develop branch to the staging server.
# Called by GitHub Actions via SSH, or manually: ssh deploy@<ip> /opt/tatl/infra/scripts/deploy.sh
set -euo pipefail

APP_ROOT="/opt/tatl"
PORTAL="${APP_ROOT}/apps/portal"

set -a
source "${APP_ROOT}/.env.production"
set +a
export RAILS_ENV=production

echo "── Pulling latest from develop ──"
cd "$APP_ROOT"
git fetch origin develop
git reset --hard origin/develop

echo "── Installing gems ──"
cd "$PORTAL"
bundle config set --local deployment true
bundle config set --local without "development test"
bundle install --jobs 4 --quiet

echo "── Running migrations ──"
bin/rails db:migrate

echo "── Precompiling assets ──"
bin/rails assets:precompile

echo "── Restarting services ──"
sudo systemctl restart tatl-web
sudo systemctl restart tatl-worker

echo "── Health check ──"
sleep 3
if curl -sf http://localhost:3000/up > /dev/null; then
  echo "Deploy complete - health check passed"
else
  echo "ERROR: Health check failed!"
  sudo journalctl -u tatl-web --no-pager -n 30
  exit 1
fi
