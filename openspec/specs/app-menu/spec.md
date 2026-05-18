# app-menu

## Purpose

The authenticated landing menu page (top-level navigation entry list) and the shared footer that displays build provenance (commit hash + GitHub links).

## Requirements

### Requirement: Authenticated menu page at root

The authenticated root path SHALL render a menu page that lists the application's top-level destinations as the first screen a signed-in operator sees after sign-in. The menu SHALL contain at least one entry. Entries that point to implemented capabilities SHALL be rendered as hyperlinks to the corresponding route; entries that point to capabilities not yet implemented SHALL be rendered as disabled placeholders (not links) with a label that clearly marks them as future work.

#### Scenario: Sign-in lands on the menu page

- **WHEN** an unauthenticated user successfully signs in with the operator credentials
- **THEN** they are redirected to `GET /`
- **AND** the response renders the menu page with HTTP status 200

#### Scenario: Donors entry links to the donor index

- **WHEN** a signed-in user views the menu page
- **THEN** the page contains an entry whose visible text is `Donors`
- **AND** that entry is rendered as a hyperlink whose `href` is `/donors`

#### Scenario: Sign out remains available

- **WHEN** a signed-in user views the menu page
- **THEN** the page contains a control that signs the user out via `DELETE /session`

### Requirement: Build provenance footer

Every page rendered with the application's default layout SHALL include a footer that identifies the running build. The footer SHALL display the abbreviated Git commit hash that the application was built from and SHALL provide a link to the GitHub repository.

#### Scenario: Footer shows the short commit hash

- **WHEN** a signed-in user views the menu page
- **THEN** the page footer displays the first 7 characters of the commit SHA the application was built from
- **AND** that hash is rendered as a link to `https://github.com/generalpf/ChristmasCheer/commit/<full-sha>`

#### Scenario: Footer links to the repository

- **WHEN** a signed-in user views the menu page
- **THEN** the page footer contains a link with visible text identifying the GitHub repository
- **AND** the link's `href` is `https://github.com/generalpf/ChristmasCheer`

#### Scenario: Commit hash unavailable

- **WHEN** the application is running in an environment where the commit SHA cannot be determined (no build-time SHA captured, no readable Git working tree)
- **THEN** the footer renders the literal text `unknown` in place of the commit hash
- **AND** the hash is not rendered as a link
- **AND** the repository link in the footer still renders normally

### Requirement: Commit SHA captured at build time

The application SHALL determine the commit SHA it is running once at boot, preferring a value captured at container build time over any runtime Git lookup, and SHALL expose it through a single accessor so views never invoke Git directly.

#### Scenario: Production container reports the build SHA

- **WHEN** the production Docker image is built with `--build-arg GIT_COMMIT_SHA=<sha>` and run
- **THEN** the application's commit-SHA accessor returns `<sha>`
- **AND** the value is identical across requests until the process restarts

#### Scenario: Development falls back to the working tree

- **WHEN** the application is started in the `development` environment from inside a Git working tree with no `GIT_COMMIT_SHA` env var set
- **THEN** the commit-SHA accessor returns the SHA reported by `git rev-parse HEAD` for that working tree
