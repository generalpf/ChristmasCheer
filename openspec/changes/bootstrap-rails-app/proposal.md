## Why

The Brandon-Westman Christmas Cheer charity currently runs on a single-user Microsoft Access database, which blocks remote access for the lone volunteer maintainer and makes reporting painful. Before any donor, donation, import, or reporting feature can land, the project needs a working Rails 8 + PostgreSQL skeleton checked into this repository so subsequent OpenSpec changes have somewhere to apply.

## What Changes

- Add a Rails 8 application at the repository root (or in `app/` — see design) configured for PostgreSQL.
- Configure development and test environments with PostgreSQL via `bin/setup` so a fresh clone runs the full stack with one command.
- Lock Ruby and Rails versions (`.ruby-version`, `Gemfile`) to a single supported pair.
- Add a default authenticated root route gated by Rails 8's built-in authentication generator (single-volunteer use case — no public sign-up).
- Wire up the Rails-omakase default toolchain (Propshaft, Importmap, Hotwire, Solid Queue, Solid Cache, Solid Cable) without adding extras.
- Add a minimal CI workflow (GitHub Actions) that runs `bin/rails db:prepare` plus `bin/rails test` against PostgreSQL.
- Update `.gitignore` and `README` so the bootstrap is reproducible.

## Capabilities

### New Capabilities
- `app-bootstrap`: Establishes the baseline Rails 8 application skeleton, database configuration, authentication scaffold, and CI pipeline that future capabilities build on.

### Modified Capabilities
<!-- None. No prior specs exist in openspec/specs/. -->

## Impact

- Creates the initial application code (Gemfile, `config/`, `app/`, `bin/`, `db/`, etc.) — the repo currently contains only docs and OpenSpec scaffolding.
- Adds runtime dependencies: Ruby (pinned), Rails 8, PostgreSQL 14+, Node-free asset pipeline (Propshaft + Importmap).
- Adds a GitHub Actions workflow file (`.github/workflows/ci.yml`).
- No data migration or production hosting in scope — those are deferred to later changes.
