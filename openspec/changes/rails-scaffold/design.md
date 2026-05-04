## Context

The repository today is empty of application code: only `docs/` (Access screenshots and a sample report PDF) and `openspec/` (this workflow) exist at the root. There is no `Gemfile`, no `config/`, no `bin/`. Brandon-Westman Christmas Cheer's existing system is a single-user Microsoft Access database (`DonorT`, donations table, lookup tables for affiliate/category/courtesy-title/city-town/source/payment/publication, plus reports). One volunteer maintains the database; uptime requirements are low; donation throughput is seasonal (peaks Nov–Jan).

The contributor team is small (likely one or two developers, hobby cadence). Cost matters — there is no DBA, no SRE, no CI budget beyond GitHub's free tier.

## Goals / Non-Goals

**Goals:**
- A `rails new`-shaped repo that boots, tests pass, lint passes, and CI is green on first push.
- Sensible defaults that match Rails 8 conventions ("omakase") rather than bespoke choices, so future contributors recognize the layout.
- A working authentication scaffold present in the codebase but not yet used to gate any controller — proves the generator works without coupling to a feature.
- A `bin/setup` that takes a fresh clone to a running app in one command.

**Non-Goals:**
- Domain modeling (Donor, Donation, lookup tables). Deferred to follow-up changes.
- Data migration tooling from `.accdb`. Deferred.
- Production deployment / hosting decisions. Deferred.
- Front-end framework choice beyond Rails 8 defaults (Hotwire + import maps). No Tailwind, no React in this change.
- Email sending infrastructure (tax receipts). Deferred.

## Decisions

### Rails 8.x with PostgreSQL
- **Choice**: `rails new . --database=postgresql --skip-bundle` (then bundle separately so the command is reproducible), targeting the latest Rails 8.x patch.
- **Why over Rails 7**: Rails 8 ships built-in authentication generators, Solid Queue/Cable/Cache (no Redis dependency), and Propshaft as default. All three reduce future setup work.
- **Why over Sinatra/Hanami**: this is a single-developer maintained app; convention-over-configuration wins. No team familiarity argument for alternatives.
- **Why PostgreSQL over SQLite**: Rails 8 makes SQLite viable, but the charity's reports include aggregations across years (one-time vs repeat donors, donor categories, publication-by-year). Window functions and richer query planning matter more than the operational simplicity of a file DB. The contributor environment cost is a `brew install postgresql@16` — acceptable.

### Ruby version
- **Choice**: pin to the latest stable Ruby 3.x supported by the chosen Rails 8 patch via `.ruby-version`. (Specific patch version chosen at implementation time so it matches what `rbenv install -l` shows then.)
- **Why**: a pinned version makes CI deterministic and avoids "works on my machine" bugs from minor-version drift.

### Authentication: Rails 8 generator, not Devise
- **Choice**: `bin/rails generate authentication` (creates `User`, `Session`, `PasswordReset` models, controllers, mailers).
- **Why over Devise**: Rails 8's generator produces code we own and can read, with no gem version churn. Devise's extra features (lockable, confirmable, OmniAuth) aren't on the roadmap; the cost of carrying a generic auth gem is higher than its benefit for one charity admin.
- **Trade-off**: if we later want third-party login (Google for board members), we'll add `omniauth-google-oauth2` on top — that's straightforward.

### Test framework: Minitest (Rails 8 default)
- **Choice**: keep the Minitest + fixtures + `ActionDispatch::IntegrationTest` stack out of the box. Add Capybara + Selenium for system tests as Rails 8 defaults provide.
- **Why over RSpec**: no team preference established; defaults reduce setup. Minitest tests are easier for a casual contributor to read because they're plain Ruby.

### Lint and security: rails-omakase + Brakeman + ERB Lint
- **Choice**: include `rubocop-rails-omakase`, `brakeman`, and `erb_lint` in the `:development` group; expose `bin/rubocop`, `bin/brakeman`.
- **Why**: omakase styles prevent bikeshedding. Brakeman catches the OWASP-class issues that matter for a public donation app once we get that far. ERB Lint catches view issues that RuboCop misses.

### CI: GitHub Actions, single workflow
- **Choice**: one `.github/workflows/ci.yml` with three jobs (lint, scan, test) on Ubuntu, using `ruby/setup-ruby` and a `services: postgres:16` container for the test job.
- **Why**: simplest thing that works. Free for public repos. Caches `vendor/bundle` between runs.

### Repository layout
- **Choice**: place the Rails app at the repo root (not in a `web/` subdirectory). Keep `docs/` and `openspec/` siblings to standard Rails directories.
- **Why**: there is no second app planned (no mobile client, no separate admin). A subdirectory adds path indirection for no benefit.

### Placeholder root route
- **Choice**: `HomeController#index` rendering a tiny ERB view with the charity name and "Coming soon".
- **Why**: gives a smoke-testable target for `bin/dev` and CI integration tests, without committing to UX.

## Risks / Trade-offs

- **PostgreSQL dependency raises contributor onboarding cost** → Mitigation: `bin/setup` runs `brew bundle` (added) to install Postgres if missing on macOS; README documents Linux equivalent.
- **Rails 8 is recent (released Sept 2024); third-party gems may lag** → Mitigation: stick to omakase gems in this change; defer any niche gem decisions to the changes that need them.
- **Built-in auth generator is newer and less battle-tested than Devise** → Mitigation: we own the generated code; we can patch in place. Acceptable risk because no donor data is yet in the system.
- **Pinning Ruby version means contributors must use rbenv/asdf** → Mitigation: this is standard for Rails projects; documented in README.
- **No production deploy story yet** → Mitigation: explicitly a non-goal; tracked as a future change so it isn't forgotten.

## Migration Plan

There is no existing system to migrate from in this change — the repo has no app code today. Steps:

1. Run `rails new` in a working tree, commit the result.
2. Run the auth generator, commit.
3. Add tooling (RuboCop, Brakeman, ERB Lint) to the Gemfile and configs.
4. Add `bin/setup`, `bin/dev` (the latter ships with Rails 8), README, `.github/workflows/ci.yml`.
5. Verify locally: `bin/setup && bin/rails test && bin/rubocop && bin/brakeman && bin/dev` boots on `:3000`.
6. Push; confirm CI is green.

**Rollback**: this is the first change; rollback is `git revert` of the merge commit. No data is at risk.

## Open Questions

- None blocking implementation. Future-change questions (deploy target, front-end framework, email provider) are deferred deliberately.
