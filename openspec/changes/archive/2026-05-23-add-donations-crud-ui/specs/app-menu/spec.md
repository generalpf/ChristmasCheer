## ADDED Requirements

### Requirement: Donations entry links to the donations index

The authenticated menu page SHALL contain an entry whose visible text is `Donations` and SHALL render that entry as a hyperlink whose `href` is `/donations`.

#### Scenario: Donations entry is a hyperlink to /donations

- **WHEN** a signed-in user views the menu page
- **THEN** the page contains an entry whose visible text is `Donations`
- **AND** that entry is rendered as a hyperlink whose `href` is `/donations`
