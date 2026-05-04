# Christmas Cheer

A Rails web application for Brandon-Westman Christmas Cheer (est. 1955), replacing the long-running MS Access donor and donation database.

This repository currently contains only the application skeleton. Domain models (donors, donations, reports, tax-receipt mailers) land in subsequent OpenSpec changes — see `openspec/changes/`.

## Prerequisites

| Tool       | Version | Notes                                                |
|------------|---------|------------------------------------------------------|
| Ruby       | 3.4.5   | Pinned in `.ruby-version`. Use rbenv/asdf to manage. |
| PostgreSQL | 16+     | The dev and test databases live here.                |
| Bundler    | 2.x     | Comes with Ruby 3.4.                                  |

### Installing PostgreSQL

```sh
# macOS
brew install postgresql@16
brew services start postgresql@16

# Linux (Debian/Ubuntu)
sudo apt-get install postgresql-16
sudo systemctl start postgresql
```

## Local setup

From a fresh clone:

```sh
bin/setup
```

This script verifies PostgreSQL is reachable, runs `bundle install`, prepares the dev and test databases, and clobbers stale assets. It exits non-zero with a clear message if PostgreSQL is missing or not running.

## Day-to-day commands

```sh
bin/dev               # Boot the dev server (default port 3000)
bin/rails test        # Run the Minitest suite
bin/rails test:system # Run system tests (Capybara + Selenium)
bin/rubocop           # Ruby linter (rails-omakase styles)
bin/erb_lint --lint-all  # ERB template linter
bin/brakeman --no-pager  # Static security scan
```

## Project layout

- `app/`, `config/`, `db/`, `bin/`, `test/`, `lib/` — standard Rails directories.
- `docs/` — reference material from the legacy MS Access system (schemas, sample reports).
- `openspec/` — spec-driven change workflow. See `openspec/changes/` for active proposals and `openspec/specs/` for archived capabilities.

## Authentication

The Rails 8 built-in authentication scaffold is wired (`User`, `Session`, `PasswordReset`). No application controllers require login yet — the placeholder home page is intentionally public.

## Continuous integration

GitHub Actions (`.github/workflows/ci.yml`) runs lint (`rubocop`, `erb_lint`), security (`brakeman`, `bundler-audit`, `importmap audit`), and tests (`rails test`, `rails test:system`) on every push and pull request.
