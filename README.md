# Tatl

A resident portal for HOA policies, accounting, tickets, and a knowledge-graph chat assistant.

Repo: <https://github.com/MattGLut/Tatl>

This monorepo is being built in thin slices. The portal foundation, authentication, authorization, accounting ledger, native ticketing, and AWS staging deployment are complete. Later slices add announcements, violation tracking, architectural review requests, online payments, document search (LightRAG), and an AI chat assistant (n8n).

## Repository layout

```
apps/
  portal/          Rails 8 app
infra/
  aws/             AWS provisioning scripts
  caddy/           Caddyfile per environment
  scripts/         Server setup + deploy scripts
  systemd/         systemd unit files for Puma + Solid Queue
.github/
  workflows/       CI + deploy-staging pipelines
docs/              Architecture, runbooks (later slices)
```

## What's here

Rails 8.1 app at `apps/portal/` with:

- PostgreSQL via the `tatl` role on a local PostgreSQL 18 service
- Hotwire (Turbo + Stimulus), Propshaft, Tailwind CSS, importmap
- Solid Queue / Solid Cache / Solid Cable (Rails 8 defaults)
- Devise authentication (`:database_authenticatable`, `:registerable`, `:recoverable`, `:rememberable`, `:validatable`, `:confirmable`, `:lockable`, `:trackable`)
- Custom Tailwind-styled Devise views (sign-in, sign-up, password reset, confirmation, unlock, edit profile)
- Pundit authorization, with `User` role enum (`resident`, `board`, `treasurer`, `admin`)
- **Core domain models:**
  - `Property` (unit/lot with address, lot number, property type)
  - `Membership` (links users to properties with role: owner/resident/tenant and date range)
  - `Document` (HOA documents with Active Storage file attachments, categories, published/draft state)
- Full CRUD UI for properties, memberships (nested), and documents with category filtering
- Pundit policies: staff (admin/board/treasurer) manages; residents view their own properties and published documents
- **Doorkeeper OIDC Identity Provider** (RS256, auth code flow, custom `roles` claim, JWKS endpoint)
- **Accounting ledger (single-entry):**
  - `Account` (chart of accounts: operating, reserve, income, expense)
  - `Transaction` (signed amounts with money-rails, Active Storage attachments)
  - `DuesAssessment` (billed to properties, auto-status: open/partial/paid/overdue)
  - `DuesPayment` (payments against assessments with auto-recalculation)
  - `BudgetLine` (annual budget per account)
- Treasurer reports: financial summary with chartkick charts, dues aging by bucket, reserve balance over time
- Accounting namespace with Pundit policies: treasurer/admin write, board read, residents see own dues
- **Native ticketing system:**
  - `Ticket` (subject, description, category, priority, status, optional property link)
  - `TicketComment` (threaded comments with optional file attachments)
  - Tickets namespace with Pundit policies: residents submit/view own, staff manage all
  - TicketMailer notifications (new ticket to admin, status changes to resident, comment replies)
- **Role-based modular dashboard:** guest landing page, resident view (my properties, my tickets, recent documents, outstanding dues), staff view (open ticket counts, all documents, treasurer/admin callouts). Composed from `home/dashboards/` partials driven by Pundit policy scopes.
- SendGrid SMTP for transactional email in staging/production (confirmations, password resets, unlocks)
- Letter Opener Web at `/letters` for development emails
- RSpec test suite with FactoryBot, shoulda-matchers, pundit-matchers, Capybara + Cuprite, WebMock, VCR, SimpleCov
- RuboCop (rails-omakase + rspec + performance + capybara + factory_bot), erb_lint, Brakeman, bundler-audit
- `bin/ci` - one-command lint + security + spec runner

## Prerequisites

Already on the local dev machine:

- Ruby 3.4.x (matches `apps/portal/.ruby-version`)
- Bundler 2+/4+
- Node 20+ (for any future bundling)
- PostgreSQL 18 running as a Windows service (`postgresql-x64-18`)
- The PostgreSQL `bin` directory on PATH (`C:\Program Files\PostgreSQL\18\bin`)

The local Postgres has:

- Role: `tatl` (password: `tatl_dev`, set in `.env.development`)
- Databases: `tatl_development`, `tatl_test`

## First-time clone setup

```powershell
git clone git@github.com:MattGLut/Tatl.git
cd Tatl

# 1. Add Postgres bin to your PATH (per-session or system)
$env:PATH = "C:\Program Files\PostgreSQL\18\bin;" + $env:PATH

# 2. Install gems
cd apps\portal
bundle install

# 3. Copy the env template and fill in real values for your machine
copy .env.development.example .env.development

# 4. Provision a Rails master key (see "Credentials" below before running this)
ruby bin/rails credentials:edit
# Press save/exit in the editor; this creates config/master.key and re-encrypts config/credentials.yml.enc.

# 5. Create the local databases (only needed once per machine)
psql -U postgres -h localhost -c "CREATE ROLE tatl WITH LOGIN PASSWORD 'tatl_dev' CREATEDB;"
createdb -U postgres -h localhost -O tatl tatl_development
createdb -U postgres -h localhost -O tatl tatl_test

# 6. Migrate
ruby bin/rails db:migrate
ruby bin/rails db:test:prepare

# 7. Run the app (builds Tailwind CSS, then starts Puma)
ruby bin/dev
```

Then visit <http://localhost:3000>. Mailer previews land at <http://localhost:3000/letters>.

> **Tailwind note:** `bin/dev` runs a one-shot `tailwindcss:build` before starting the server. If you add new Tailwind classes while the server is running, restart it or run `ruby bin/rails tailwindcss:build` in a separate terminal. On Linux/macOS you can use `foreman start -f Procfile.dev` to get a live-reloading CSS watcher instead.

## Credentials

Tatl uses Rails encrypted credentials (`config/credentials.yml.enc`). The `master.key` that decrypts it is **not** in the repo - each environment supplies its own:

- **Local dev:** `config/master.key` is generated by `bin/rails credentials:edit` on first run. Treat it like a password; it lives in your home directory only.
- **Staging / production:** the key is provided via the `RAILS_MASTER_KEY` environment variable (sourced from AWS Secrets Manager when we get to those slices).

If `config/credentials.yml.enc` ever fails to decrypt for you (different key than the committed file), you can re-create it by deleting both files and re-running `bin/rails credentials:edit`. We will keep `credentials.yml.enc` empty until we actually have shared secrets to encrypt.

## Tests

```powershell
cd apps\portal
bundle exec rspec
```

## Full CI suite locally

```powershell
cd apps\portal
ruby bin/ci
```

This runs `bundler-audit`, `brakeman`, `rubocop`, `erb_lint`, then `rspec`.

## Branch model

- **`develop`** - integration branch; every push auto-deploys to staging
- **`master`** - stable; production deploys (later slice)
- **Feature branches** - PR into `develop`; CI runs on every PR

## Staging deployment

Staging runs on a single EC2 `t3.small` in `us-east-2` with RDS PostgreSQL. Rails runs natively (no Docker) via systemd, with Caddy as the reverse proxy.

### Provisioning (one-time)

1. Install [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and run `aws configure` (region: `us-east-2`)
2. Run the provisioning script:

```bash
chmod +x infra/aws/provision-staging.sh
./infra/aws/provision-staging.sh
```

3. SSH into the new EC2 and run server setup:

```bash
ssh -i ~/.ssh/tatl-staging.pem ubuntu@<elastic-ip>
sudo bash /tmp/setup-server.sh   # or clone first, then run from repo
```

4. Create `/opt/tatl/.env.production` on the server (template printed by setup script)
5. Run the first deploy: `sudo -u deploy /opt/tatl/infra/scripts/deploy.sh`

### GitHub Secrets

Add these in **Settings > Secrets and variables > Actions**:

| Secret | Value |
|---|---|
| `STAGING_HOST` | EC2 elastic IP (`3.146.142.26`) |
| `STAGING_SSH_KEY` | Contents of `~/.ssh/tatl-staging.pem` |
| `RAILS_MASTER_KEY` | Contents of `apps/portal/config/master.key` |
| `TATL_DB_HOST` | RDS endpoint hostname |
| `TATL_DB_PASSWORD` | RDS master password |
| `SECRET_KEY_BASE` | Output of `bundle exec rails secret` |
| `SENDGRID_API_KEY` | SendGrid API key |
| `TATL_MAILER_SENDER` | From address for emails (e.g. `no-reply@yourdomain.com`) |

The deploy workflow writes `/opt/tatl/.env.production` on every deploy from these secrets -- no need to SSH in to manage env vars.

### CI pipeline

Every PR and push to `develop`/`master` runs: Brakeman, bundler-audit, importmap audit, RuboCop, erb_lint, and RSpec (with a Postgres service container). See `.github/workflows/ci.yml`.

### Auto-deploy

When CI passes on `develop`, `.github/workflows/deploy-staging.yml` SSHs to the staging EC2 and runs `infra/scripts/deploy.sh` (pull, bundle, migrate, precompile, restart, health check).

## Email

- **Development:** emails are intercepted by `letter_opener_web` and viewable at <http://localhost:3000/letters>. No real emails are sent.
- **Staging / Production:** emails are sent via [SendGrid](https://sendgrid.com/) SMTP. The `SENDGRID_API_KEY` and `TATL_MAILER_SENDER` GitHub Secrets are written to `.env.production` on every deploy automatically (see GitHub Secrets table above).

Devise sends confirmation, password reset, unlock, email change, and password change emails automatically.

## Roadmap

### Next up -- core HOA features

1. **Announcements** -- board-posted news feed with optional email blast to residents
2. **Violation tracking** -- log violations against properties, warning/fine/resolved workflow
3. **Architectural review requests (ARB)** -- resident submits modification request with photos, board reviews and approves/denies
4. **Online dues payment** -- Stripe integration for resident self-service payment, auto-reconciles against assessments
5. **Meeting minutes & calendar** -- schedule board meetings, post agendas, publish approved minutes

### Later -- quality of life

6. **Common area reservations** -- clubhouse/pool/pavilion booking with calendar and conflict detection
7. **Bulk notifications** -- targeted email to resident groups (all, by street, by property)
8. **Voting / polls** -- one-vote-per-property balloting for elections and bylaw amendments
9. **Resident directory** -- opt-in contact directory with privacy controls

### Infrastructure & AI

10. **Document search (LightRAG)** -- AI-powered search across CC&Rs, bylaws, and meeting minutes
11. **Chat assistant (n8n)** -- natural-language Q&A against the document knowledge base via Turbo Streams
12. **Production environment** -- EC2 + RDS + S3 + Cloudflare DNS + HTTPS + deploy-to-prod workflow
