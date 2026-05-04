## Context

The repository currently contains only `docs/` (Access reference material) and `openspec/` (this proposal system). Every future change — donor schema, donation tracking, importer, reporting — needs to compile and run against an actual Rails app. Without a baseline, each subsequent change would have to re-relitigate framework, database, and CI choices.

Constraints from the project memory:
- One volunteer maintainer; no DBA or SRE.
- Cost-sensitive, low-throughput, seasonal usage (Nov–Jan peak).
- Rails-omakase preference; defer fancy infrastructure until a feature actually needs it.
- The Access app is single-user, so there is no concurrency, replication, or HA target to inherit.

## Goals / Non-Goals

**Goals:**
- A fresh clone runs `bin/setup && bin/rails server` against PostgreSQL with no extra steps.
- A single, opinionated Rails 8 stack — no premature abstractions or alternative gem choices.
- CI proves the app boots and tests run on every push.
- Authentication exists from day one so private routes are the default.

**Non-Goals:**
- Production hosting, deploy automation, secrets management — out of scope.
- Donor/donation models, importer, reports — those are separate OpenSpec changes that depend on this one.
- Multi-tenant or multi-user role design — the app supports one operator.
- JavaScript build tooling beyond Importmap (no esbuild, Vite, etc.).

## Decisions

### Decision: Rails 8 with the omakase defaults
**Choice:** Generate the app with `rails new . --database=postgresql` using Rails 8 defaults (Propshaft, Importmap, Hotwire/Turbo/Stimulus, Solid Queue, Solid Cache, Solid Cable).

**Rationale:** Rails 8's omakase stack covers background jobs, caching, and websockets via SQLite-backed adapters out of the box — no Redis, no separate worker host. For a single-volunteer charity app, this is exactly the operational simplicity we want.

**Alternatives considered:**
- *Rails 7.x*: Older, requires picking Sidekiq/Redis or accepting slower defaults. Rejected — Rails 8 is the current stable line and the user's project memory already targets it.
- *Hanami / Sinatra*: Smaller surface area, but the volunteer benefits more from Rails' batteries-included generators (scaffolds, mailers, Active Storage) than from minimalism.

### Decision: PostgreSQL (not SQLite) from the start
**Choice:** PostgreSQL 14+ for development, test, and the eventual production database.

**Rationale:** The annual report needs window functions and aggregations (one-time vs. repeat donors is the volunteer's pain point); PostgreSQL gives us those without a migration later. Hosting PG cheaply on a single small VM or managed tier (Neon free tier, Supabase, Fly Postgres) is well-trodden ground.

**Alternatives considered:**
- *SQLite*: Rails 8 supports it well, and the data volume is tiny. Rejected because reporting queries are the explicit unlock for this migration; reaching for PG later is more pain than starting there.

### Decision: Rails 8 built-in authentication generator (single user)
**Choice:** Run `bin/rails generate authentication` and seed a single operator account from environment variables on first boot.

**Rationale:** The authenticated user count is one. Devise is overkill. Rails 8's built-in authentication is enough for a private app with no public sign-up.

**Alternatives considered:**
- *Devise*: Adds a dependency and configuration surface area for features (confirmations, lockable, OAuth) we don't need.
- *No auth, IP allow-list*: Brittle when the volunteer travels or works from new networks.

### Decision: Single GitHub Actions workflow, PG service container
**Choice:** One `.github/workflows/ci.yml` that runs on push and PR, boots a `postgres:16` service, runs `bin/rails db:prepare` and `bin/rails test`.

**Rationale:** Smallest possible CI that proves the app still boots and the test suite passes. Linting/security scans can be added when we have actual code worth linting.

**Alternatives considered:**
- *No CI yet*: Tempting given there's no team — rejected because catching "it doesn't even boot" regressions early is cheap.
- *Multi-job matrix (Ruby versions × Rails versions)*: Premature; we pin one version of each.

### Decision: App lives at the repository root (not a subdirectory)
**Choice:** Run `rails new .` so `Gemfile`, `app/`, `config/`, etc. are at the repo root alongside `docs/` and `openspec/`.

**Rationale:** This is a single-app repo. Nesting under `app/` (or `web/`) buys nothing and complicates `bin/setup` paths.

**Alternatives considered:**
- *Subdirectory `app/`*: Would conflict with Rails' own `app/` convention. Rejected.
- *Subdirectory `web/`*: No second deployable is planned. Rejected.

## Risks / Trade-offs

- **Risk:** Rails 8's built-in authentication is newer than Devise and has fewer community guides. → **Mitigation:** Stick to the generated code; don't customize until a real need shows up. Devise is a reversible swap later.
- **Risk:** Solid Queue / Solid Cache use the database and add table churn. → **Mitigation:** Acceptable at this scale; revisit only if the donor table contention shows up in practice (it won't for years).
- **Risk:** Putting the app at the repo root means OpenSpec tooling shares a directory with Rails — possible name collisions (e.g., a future `lib/openspec.rb`). → **Mitigation:** Low likelihood; the `openspec/` folder is at the root and the Rails autoloader doesn't scan it.
- **Trade-off:** Choosing PG over SQLite means the volunteer (or whoever takes over) needs Postgres installed locally. `bin/setup` plus a one-line Homebrew/Postgres.app instruction in the README absorbs this cost.

## Migration Plan

This is a greenfield bootstrap; nothing to migrate.

1. Generate the Rails app at the repo root.
2. Commit the initial scaffold in one commit so the diff is reviewable.
3. Run `bin/rails generate authentication` and commit separately.
4. Add the GitHub Actions workflow and confirm it goes green on push.
5. Update README with setup instructions.

Rollback: If the bootstrap is wrong, revert the commits — no data exists yet to lose.

## Open Questions

- Which Ruby version to pin? (Lean toward the latest patch on Ruby 3.3 or 3.4 — defer to whatever `rbenv install -l` suggests at implementation time.)
- Where should the seeded operator credentials live? (Likely `Rails.application.credentials` plus a one-time `db/seeds.rb` block reading `ENV` — confirm during implementation.)
