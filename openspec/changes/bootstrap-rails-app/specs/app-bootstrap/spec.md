## ADDED Requirements

### Requirement: Rails 8 application skeleton

The repository SHALL contain a working Rails 8 application generated at the repository root, configured to use PostgreSQL for development, test, and production database environments.

#### Scenario: Fresh clone boots

- **WHEN** a contributor clones the repository on a machine with the pinned Ruby version and a running PostgreSQL server
- **AND** runs `bin/setup`
- **THEN** dependencies are installed, the development and test databases are created and migrated, and the command exits with status 0

#### Scenario: Server starts

- **WHEN** a contributor runs `bin/rails server` after a successful `bin/setup`
- **THEN** the server boots without error and serves a 200 response (after authentication) on `GET /`

#### Scenario: Database adapter is PostgreSQL

- **WHEN** the application loads any environment (`development`, `test`, `production`)
- **THEN** `ActiveRecord::Base.connection.adapter_name` equals `"PostgreSQL"`

### Requirement: Pinned Ruby and Rails versions

The repository SHALL pin a single Ruby version via `.ruby-version` and a single Rails version via `Gemfile`/`Gemfile.lock`, and CI SHALL fail if either drifts.

#### Scenario: Ruby version is pinned

- **WHEN** a contributor inspects the repository root
- **THEN** a `.ruby-version` file exists and contains a single MRI Ruby version string (e.g., `3.4.x`)

#### Scenario: Rails version is pinned

- **WHEN** a contributor inspects `Gemfile.lock`
- **THEN** the `rails` gem is locked to a Rails 8.x version

### Requirement: Authenticated root route

The application SHALL require authentication for all non-public routes, including the root path, using Rails 8's built-in authentication generator.

#### Scenario: Unauthenticated request to root

- **WHEN** an unauthenticated user requests `GET /`
- **THEN** the application redirects them to the sign-in page with HTTP status 302

#### Scenario: Authenticated request to root

- **WHEN** a user signed in as the seeded operator account requests `GET /`
- **THEN** the application returns HTTP status 200 and renders the home view

#### Scenario: No public sign-up

- **WHEN** an unauthenticated user requests any sign-up or registration URL
- **THEN** the application returns HTTP status 404 (no route registered)

### Requirement: Omakase Rails 8 stack

The application SHALL use the Rails 8 default stack — Propshaft, Importmap, Hotwire (Turbo + Stimulus), Solid Queue, Solid Cache, and Solid Cable — without substituting alternative gems for these concerns.

#### Scenario: Default gems present

- **WHEN** a contributor inspects `Gemfile.lock`
- **THEN** `propshaft`, `importmap-rails`, `turbo-rails`, `stimulus-rails`, `solid_queue`, `solid_cache`, and `solid_cable` are all present
- **AND** no alternative is included for the same concern (e.g., no `sprockets-rails`, `webpacker`, `sidekiq`, `redis-rails`)

### Requirement: Continuous integration on every push

The repository SHALL include a GitHub Actions workflow that runs on every push and pull request, prepares the database against PostgreSQL, and runs the Rails test suite.

#### Scenario: Workflow triggers on push

- **WHEN** a contributor pushes a commit to any branch
- **THEN** the `ci` workflow defined in `.github/workflows/ci.yml` is triggered

#### Scenario: Workflow runs tests against PostgreSQL

- **WHEN** the `ci` workflow runs
- **THEN** it provisions a `postgres:16` (or newer) service container, runs `bin/rails db:prepare`, runs `bin/rails test`, and the job fails if any of those steps exit non-zero

### Requirement: Reproducible developer setup documentation

The `README.md` at the repository root SHALL document the steps required to install Ruby, install PostgreSQL, run `bin/setup`, and start the server.

#### Scenario: README covers setup

- **WHEN** a new contributor reads `README.md`
- **THEN** the README contains, in order, instructions for installing the pinned Ruby version, installing PostgreSQL, running `bin/setup`, and running `bin/rails server`
