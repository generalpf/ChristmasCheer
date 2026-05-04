## 1. Toolchain pin

- [x] 1.1 Decide and record the Ruby version (latest patch on the chosen 3.x line) in `.ruby-version`
- [x] 1.2 Verify `bundler` is installed at a version compatible with Rails 8 and document the command in the README setup section
- [x] 1.3 Confirm a local PostgreSQL 14+ server is available (Postgres.app or `brew install postgresql@16`) before generating the app

## 2. Generate the Rails 8 app at the repo root

- [x] 2.1 Run `rails new . --database=postgresql --skip-git` (the repo is already a git repo) and resolve any conflicts with existing `docs/` and `openspec/` directories
- [x] 2.2 Verify the generated `Gemfile` locks Rails to an `~> 8.0` version and that `propshaft`, `importmap-rails`, `turbo-rails`, `stimulus-rails`, `solid_queue`, `solid_cache`, and `solid_cable` are all present
- [x] 2.3 Confirm no alternative gems were pulled in (no `sprockets-rails`, `sidekiq`, `redis`, `webpacker`)
- [x] 2.4 Update `.gitignore` so `.bundle/`, `tmp/`, `log/`, `storage/`, and `.byebug_history` are ignored without clobbering existing entries
- [x] 2.5 Commit the bootstrap as a single, reviewable commit

## 3. Configure PostgreSQL

- [x] 3.1 Edit `config/database.yml` so development, test, and production all use the `postgresql` adapter and read credentials from environment variables (`DATABASE_URL` or discrete `*_DATABASE_*` envs) — no hard-coded user/password
- [x] 3.2 Add `bin/setup` checks that fail loudly with a helpful message if `psql` is missing or PG is not reachable
- [x] 3.3 Run `bin/setup` end-to-end on a clean checkout to confirm it creates and migrates dev + test databases
- [x] 3.4 Add a smoke test (`test/integration/boot_test.rb` or similar) asserting `ActiveRecord::Base.connection.adapter_name == "PostgreSQL"`

## 4. Authentication scaffold

- [x] 4.1 Run `bin/rails generate authentication` and review the generated migrations, models, controllers, and views
- [x] 4.2 Run the new migrations and confirm the `users` and `sessions` tables exist with the expected columns
- [x] 4.3 Remove or stub out any public sign-up routes/controllers so registration returns 404 (single-operator app)
- [x] 4.4 Add `db/seeds.rb` logic that creates the seeded operator account from `ENV["OPERATOR_EMAIL"]` and `ENV["OPERATOR_PASSWORD"]` (idempotent — `find_or_create_by!`)
- [x] 4.5 Document the env vars and the `bin/rails db:seed` step in the README
- [x] 4.6 Add a `before_action :require_authentication` (or equivalent generated helper) on `ApplicationController`
- [x] 4.7 Add a static home action mounted at `root "home#show"` and a minimal view
- [x] 4.8 Write integration tests covering: unauthenticated `GET /` redirects to sign-in, authenticated `GET /` returns 200, sign-up routes return 404

## 5. Continuous integration

- [x] 5.1 Create `.github/workflows/ci.yml` that triggers on `push` and `pull_request`
- [x] 5.2 Configure the job to use the pinned Ruby version via `ruby/setup-ruby@v1` with bundler caching
- [x] 5.3 Add a `services:` block running `postgres:16` with a healthcheck and matching `DATABASE_URL` env var
- [x] 5.4 Run `bin/rails db:prepare` and `bin/rails test` as the workflow steps
- [x] 5.5 Push the workflow and confirm a green run on the PR/branch

## 6. Documentation

- [x] 6.1 Replace any auto-generated `README.md` with one that covers: project background (link to `docs/INDEX.md`), Ruby install, Postgres install, `bin/setup`, seed env vars, `bin/rails server`, and how to run tests
- [x] 6.2 Note that follow-on OpenSpec changes (`openspec/changes/`) cover donor schema, importer, and reporting
- [x] 6.3 Verify a fresh contributor can follow the README on a clean machine and reach a running server
