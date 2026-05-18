## MODIFIED Requirements

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
