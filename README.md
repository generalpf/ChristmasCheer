# Christmas Cheer

Donor and donation tracking for the Brandon-Westman Christmas Cheer charity (est. 1955), migrating from a single-user Microsoft Access database to a Rails 8 + PostgreSQL web app.

Background and Access reference material live in [`docs/INDEX.md`](docs/INDEX.md). In-flight changes and archived specifications are tracked under [`openspec/`](openspec/) — see [`openspec/changes/`](openspec/changes/) for what's currently being worked on (donor schema, importer, and reporting follow this bootstrap).

## Requirements

- Ruby (pinned in `.ruby-version`, currently 3.4.5) — install via [asdf](https://asdf-vm.com/), [rbenv](https://github.com/rbenv/rbenv), or [mise](https://mise.jdx.dev/).
- PostgreSQL 14+ — on macOS: `brew install postgresql@16 && brew services start postgresql@16`, or use [Postgres.app](https://postgresapp.com/).
- Bundler 2.4+ (`gem install bundler`).

## Setup

```sh
bin/setup
```

This checks that `psql` is installed and PostgreSQL is reachable, runs `bundle install`, creates and migrates the development and test databases, then starts the dev server (`bin/dev`). Pass `--skip-server` to stop after database setup.

### Seeding the operator account

Christmas Cheer has a single human user. Seed the operator account by setting the credentials in your environment and running `db:seed`:

```sh
OPERATOR_EMAIL=you@example.com OPERATOR_PASSWORD='choose-a-strong-password' bin/rails db:seed
```

The seed is idempotent — re-running with the same email updates the password, never duplicates the user.

## Running the app

```sh
bin/rails server
```

Visit <http://localhost:3000>. You'll be redirected to the sign-in page; use the credentials from the operator seed above.

## Running tests

```sh
bin/rails test
```

System tests:

```sh
bin/rails test:system
```

## Continuous integration

Every push and pull request runs the full test suite, RuboCop, Brakeman, and bundler-audit against PostgreSQL via [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

## Project conventions

- OpenSpec ([`openspec/`](openspec/)) is the source of truth for proposed and accepted changes — `openspec/changes/<name>/` for in-flight, `openspec/specs/<capability>/` for archived.
- Database connection settings come from environment variables (`DATABASE_URL`, or `POSTGRES_HOST`/`POSTGRES_PORT`/`POSTGRES_USER`/`POSTGRES_PASSWORD`); see [`config/database.yml`](config/database.yml).
- This is a single-operator app. There is no public sign-up; new accounts must be seeded.
