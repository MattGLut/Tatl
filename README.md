# Tatl

A resident portal for HOA policies, accounting, tickets, and a knowledge-graph chat assistant.

This monorepo is being built in thin slices. Slice 1 is the Rails portal foundation. Later slices add Doorkeeper/OIDC, accounting, document indexing into LightRAG, n8n-driven chat, Zammad and Discourse integrations, and AWS deployment.

## Repository layout

```
apps/
  portal/        Rails 8 app (this slice)
infra/           Docker Compose, Caddy, AWS notes (later slices)
docs/            Architecture, runbooks, environment notes (later slices)
.github/         CI/CD workflows (later slice)
```

## Slice 1 - what's here

Rails 8.1 app at `apps/portal/` with:

- PostgreSQL via the `tatl` role on a local PostgreSQL 18 service
- Hotwire (Turbo + Stimulus), Propshaft, Tailwind CSS, importmap
- Solid Queue / Solid Cache / Solid Cable (Rails 8 defaults)
- Devise authentication (`:database_authenticatable`, `:registerable`, `:recoverable`, `:rememberable`, `:validatable`, `:confirmable`, `:lockable`, `:trackable`)
- Pundit authorization, with `User` role enum (`resident`, `board`, `treasurer`, `admin`)
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

## Setup

```powershell
# 1. Add Postgres bin to your PATH (per-session or system)
$env:PATH = "C:\Program Files\PostgreSQL\18\bin;" + $env:PATH

# 2. Install gems
cd apps\portal
bundle install

# 3. Copy the env template (already populated for local dev)
copy .env.development.example .env.development

# 4. Migrate
ruby bin/rails db:migrate
ruby bin/rails db:test:prepare

# 5. Run the app
ruby bin/rails server
```

Then visit `http://localhost:3000`. Mailer previews land in `http://localhost:3000/letters`.

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

## Roadmap (later slices)

1. Doorkeeper + doorkeeper-openid_connect (OIDC IdP)
2. Domain models: Property, Membership, Document, Account, Transaction, Dues
3. Document upload with LightRAG sync job
4. Chat UI proxied to n8n with Turbo Streams
5. Docker Compose: Postgres, Zammad, Discourse, n8n, LightRAG, Caddy
6. Zammad and Discourse SSO via Tatl OIDC
7. AWS deployment: EC2 + RDS + S3 + ECR + Cloudflare DNS + SendGrid (staging then prod, in `us-east-2`)
8. GitHub Actions CI/CD with OIDC role assumption
