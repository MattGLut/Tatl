#!/usr/bin/env bash
# One-time server setup for a fresh Ubuntu 24.04 EC2 instance.
#
# Run as root (or via sudo) on the EC2 instance:
#   sudo bash setup-server.sh
#
# After this script completes you should:
#   1. Create /opt/tatl/.env.production (see template at the end of output)
#   2. Run the first deploy: sudo -u deploy /opt/tatl/infra/scripts/deploy.sh
set -euo pipefail

RUBY_VERSION="3.4.8"
DEPLOY_USER="deploy"
APP_ROOT="/opt/tatl"
REPO_URL="https://github.com/MattGLut/Tatl.git"
REPO_BRANCH="develop"

echo "=== Tatl server setup (Ubuntu 24.04) ==="

# ── System packages ──────────────────────────────────────────────────
echo "── Installing system packages ──"
apt-get update -qq
apt-get install -y --no-install-recommends \
  build-essential git curl wget \
  libpq-dev libyaml-dev libssl-dev libreadline-dev zlib1g-dev \
  libffi-dev libgdbm-dev libncurses5-dev \
  libvips imagemagick \
  postgresql-client \
  autoconf bison rustc

# ── nginx ─────────────────────────────────────────────────────────────
echo "── Installing nginx ──"
apt-get install -y nginx

# ── Deploy user ──────────────────────────────────────────────────────
echo "── Creating deploy user ──"
if ! id "$DEPLOY_USER" &>/dev/null; then
  adduser --system --group --home "/home/${DEPLOY_USER}" --shell /bin/bash "$DEPLOY_USER"
fi

# Let deploy user restart services without a password
cat > /etc/sudoers.d/tatl-deploy <<SUDOERS
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/systemctl restart tatl-web, /bin/systemctl restart tatl-worker, /bin/systemctl restart tatl-web tatl-worker
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /usr/sbin/nginx -t
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx
${DEPLOY_USER} ALL=(ALL) NOPASSWD: /bin/journalctl *
SUDOERS
chmod 0440 /etc/sudoers.d/tatl-deploy

# Copy authorized_keys from ubuntu user so the same SSH key works
mkdir -p "/home/${DEPLOY_USER}/.ssh"
if [[ -f /home/ubuntu/.ssh/authorized_keys ]]; then
  cp /home/ubuntu/.ssh/authorized_keys "/home/${DEPLOY_USER}/.ssh/authorized_keys"
fi
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "/home/${DEPLOY_USER}/.ssh"
chmod 700 "/home/${DEPLOY_USER}/.ssh"
chmod 600 "/home/${DEPLOY_USER}/.ssh/authorized_keys" 2>/dev/null || true

# ── rbenv + Ruby ─────────────────────────────────────────────────────
echo "── Installing rbenv + Ruby ${RUBY_VERSION} ──"
RBENV_ROOT="/home/${DEPLOY_USER}/.rbenv"

if [[ ! -d "$RBENV_ROOT" ]]; then
  sudo -u "$DEPLOY_USER" git clone https://github.com/rbenv/rbenv.git "$RBENV_ROOT"
  sudo -u "$DEPLOY_USER" git clone https://github.com/rbenv/ruby-build.git "${RBENV_ROOT}/plugins/ruby-build"

  # Add rbenv to deploy user's shell
  cat >> "/home/${DEPLOY_USER}/.bashrc" <<'BASHRC'
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init - bash)"
BASHRC
fi

export PATH="${RBENV_ROOT}/bin:${RBENV_ROOT}/shims:$PATH"

if ! sudo -u "$DEPLOY_USER" "${RBENV_ROOT}/bin/rbenv" versions --bare | grep -q "^${RUBY_VERSION}$"; then
  echo "Building Ruby ${RUBY_VERSION} (this takes a few minutes)..."
  sudo -u "$DEPLOY_USER" "${RBENV_ROOT}/plugins/ruby-build/bin/ruby-build" "$RUBY_VERSION" "${RBENV_ROOT}/versions/${RUBY_VERSION}"
  sudo -u "$DEPLOY_USER" "${RBENV_ROOT}/bin/rbenv" global "$RUBY_VERSION"
  sudo -u "$DEPLOY_USER" "${RBENV_ROOT}/bin/rbenv" rehash
fi

sudo -u "$DEPLOY_USER" "${RBENV_ROOT}/shims/gem" install bundler --no-document

# ── Clone repository ─────────────────────────────────────────────────
echo "── Cloning repository ──"
if [[ ! -d "$APP_ROOT" ]]; then
  git clone --branch "$REPO_BRANCH" "$REPO_URL" "$APP_ROOT"
  chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "$APP_ROOT"
else
  echo "App directory already exists at ${APP_ROOT}"
  chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "$APP_ROOT"
fi

# Mark the repo safe for the deploy user
sudo -u "$DEPLOY_USER" git config --global --add safe.directory "$APP_ROOT"

# ── Install systemd units ───────────────────────────────────────────
echo "── Installing systemd services ──"
cp "${APP_ROOT}/infra/systemd/tatl-web.service" /etc/systemd/system/
cp "${APP_ROOT}/infra/systemd/tatl-worker.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable tatl-web tatl-worker

# ── Configure nginx ─────────────────────────────────────────────────
echo "── Configuring nginx ──"
mkdir -p /etc/ssl/cloudflare
ln -sf "${APP_ROOT}/infra/nginx/neiqhbor.conf" /etc/nginx/sites-available/neiqhbor.conf
ln -sf /etc/nginx/sites-available/neiqhbor.conf /etc/nginx/sites-enabled/neiqhbor.conf
rm -f /etc/nginx/sites-enabled/default

if [[ -f /etc/ssl/cloudflare/origin.pem && -f /etc/ssl/cloudflare/origin-key.pem ]]; then
  nginx -t && systemctl restart nginx
  systemctl enable nginx
else
  echo "WARNING: Cloudflare Origin Certificate not found."
  echo "  Place your cert at /etc/ssl/cloudflare/origin.pem"
  echo "  Place your key  at /etc/ssl/cloudflare/origin-key.pem"
  echo "  Then run: sudo nginx -t && sudo systemctl restart nginx"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  Server setup complete!"
echo "============================================================"
echo ""
echo "Ruby: $(sudo -u ${DEPLOY_USER} ${RBENV_ROOT}/shims/ruby --version)"
echo "Bundler: $(sudo -u ${DEPLOY_USER} ${RBENV_ROOT}/shims/bundle --version)"
echo "nginx: $(nginx -v 2>&1)"
echo ""
echo "Next steps:"
echo ""
echo "  1. Create the environment file:"
echo "     sudo nano /opt/tatl/.env.production"
echo ""
echo "     Paste this template and fill in real values:"
echo "     ──────────────────────────────────────────"
echo "     RAILS_ENV=production"
echo "     RAILS_MASTER_KEY=<from apps/portal/config/master.key>"
echo "     RAILS_SERVE_STATIC_FILES=true"
echo "     RAILS_LOG_TO_STDOUT=true"
echo "     TATL_DB_HOST=<RDS endpoint>"
echo "     TATL_DB_PORT=5432"
echo "     TATL_DB_USERNAME=tatl"
echo "     TATL_DB_PASSWORD=<RDS password>"
echo "     TATL_DB_NAME=tatl_staging"
echo "     SOLID_QUEUE_IN_PUMA=true"
echo "     WEB_CONCURRENCY=2"
echo "     RAILS_MAX_THREADS=3"
echo "     SECRET_KEY_BASE=<run: bundle exec rails secret>"
echo "     APP_HOST=<elastic IP or domain>"
echo "     SENDGRID_API_KEY=<your SendGrid API key>"
echo "     TATL_MAILER_SENDER=no-reply@yourdomain.com"
echo "     ──────────────────────────────────────────"
echo ""
echo "  2. Set file ownership:"
echo "     sudo chown deploy:deploy /opt/tatl/.env.production"
echo "     sudo chmod 600 /opt/tatl/.env.production"
echo ""
echo "  3. Install the Cloudflare Origin Certificate:"
echo "     sudo nano /etc/ssl/cloudflare/origin.pem      (paste cert PEM)"
echo "     sudo nano /etc/ssl/cloudflare/origin-key.pem  (paste key PEM)"
echo "     sudo chmod 600 /etc/ssl/cloudflare/origin-key.pem"
echo "     sudo nginx -t && sudo systemctl restart nginx"
echo ""
echo "  4. Run the initial deploy:"
echo "     sudo -u deploy /opt/tatl/infra/scripts/deploy.sh"
echo ""
echo "  5. Check it's running:"
echo "     curl http://localhost:3000/up"
echo "     curl -k https://localhost/up  (through nginx)"
echo ""
