## ADDED Requirements

### Requirement: Application Boots Cleanly

The system SHALL boot a Rails 8 application from this repository with no manual intervention beyond running `bin/setup` once and `bin/dev` to start the server.

#### Scenario: Fresh clone runs to a green dev server
- **WHEN** a developer with Ruby and PostgreSQL installed clones the repo and runs `bin/setup` then `bin/dev`
- **THEN** the dev server listens on port 3000 and the root URL `/` returns HTTP 200 with a placeholder home page

#### Scenario: Boot fails fast on missing prerequisites
- **WHEN** `bin/setup` runs on a machine without PostgreSQL available
- **THEN** the script exits non-zero with a message naming PostgreSQL as the missing prerequisite

### Requirement: Pinned Toolchain Versions

The system SHALL pin the Ruby version and the Rails major+minor version in source control so every contributor and CI runner uses identical versions.

#### Scenario: Ruby version is pinned
- **WHEN** a contributor inspects the repository root
- **THEN** a `.ruby-version` file exists naming the exact patch version of Ruby 3.x in use

#### Scenario: Rails version is pinned
- **WHEN** a contributor inspects `Gemfile` and `Gemfile.lock`
- **THEN** Rails is constrained to a single major.minor (8.x) line and `Gemfile.lock` records the exact patch in use

### Requirement: Default Test Suite Passes

The system SHALL ship with the Rails-default Minitest suite and at least one test that exercises the placeholder home page, so CI has signal from day one.

#### Scenario: Minitest suite is green on default branch
- **WHEN** `bin/rails test` runs on a clean checkout of the default branch
- **THEN** the command exits zero with no failures or errors

#### Scenario: Home page is covered
- **WHEN** the test suite runs
- **THEN** an integration test asserts that GET `/` returns HTTP 200 and renders the placeholder home view

### Requirement: Lint and Security Scan Are Clean

The system SHALL ship configured RuboCop (rails-omakase), ERB Lint, and Brakeman, and SHALL pass all three on the default branch.

#### Scenario: RuboCop is clean
- **WHEN** `bin/rubocop` runs on the default branch
- **THEN** the command exits zero with no offenses

#### Scenario: Brakeman is clean
- **WHEN** `bin/brakeman --no-pager` runs on the default branch
- **THEN** the command exits zero with no warnings of medium or higher confidence

### Requirement: Continuous Integration

The system SHALL run lint, security scan, and the test suite on every push and every pull request via GitHub Actions.

#### Scenario: CI runs on pull request
- **WHEN** a contributor opens a pull request against the default branch
- **THEN** GitHub Actions runs jobs that execute `bin/rubocop`, `bin/brakeman`, and `bin/rails test` and reports per-job status to the PR

#### Scenario: CI runs on push to default branch
- **WHEN** a commit is pushed to the default branch
- **THEN** the same three jobs run and the workflow status is visible in the Actions tab

### Requirement: Sensitive Files Are Ignored

The system SHALL exclude logs, temporary files, local secrets, and Rails master keys from version control.

#### Scenario: Master key is gitignored
- **WHEN** a contributor inspects `.gitignore`
- **THEN** `config/master.key` and `.env*` patterns are present and `git status` on a fresh checkout never lists them as untracked

### Requirement: README Documents Local Setup

The system SHALL provide a `README.md` that names the prerequisite tools, the setup command, the dev command, and how to run tests.

#### Scenario: README replaces stock Rails boilerplate
- **WHEN** a new contributor opens `README.md`
- **THEN** the file contains project-specific setup steps (not the default `rails new`-generated content) covering Ruby/PostgreSQL prerequisites, `bin/setup`, `bin/dev`, and `bin/rails test`
