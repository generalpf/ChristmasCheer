# visual-design

## Purpose

A centralized, framework-free visual design system for the application: brand design tokens, a restrained functional aesthetic, a global typographic/element baseline, shared page chrome, and styled common UI building blocks. It establishes the look-and-feel that every page — existing and future — inherits without bespoke per-page styling, implemented as plain CSS served by Propshaft.

## Requirements

### Requirement: Brand design tokens

The system SHALL define a single set of design tokens as CSS custom properties, covering color, typography, spacing, and surface/border treatments, drawn from the Brandon-Westman Christmas Cheer brand palette. All other styles SHALL reference these tokens rather than hard-coded values.

The color tokens SHALL include at minimum: a primary brand red (`#ED1C24`), a deep brick red for headers/emphasis (`#822D23`), a gold accent (`#FFCB05` and muted `#B0A986`), a near-black body text color (`#2F2F2E`), cream/off-white surface colors (`#EAEAE8` and white `#FFFFFF`), and a neutral grey for secondary text (`#727272`).

#### Scenario: Tokens are the single source of truth

- **WHEN** any component or element style needs a brand color, font, or spacing value
- **THEN** it references a defined CSS custom property (e.g. `var(--color-brand-red)`) rather than an inline hex code or magic number

#### Scenario: Palette matches the brand site

- **WHEN** the primary and deep-red brand tokens are inspected
- **THEN** their values equal the colors sampled from the live brand site (`#ED1C24` and `#822D23` respectively)

### Requirement: Restrained, functional aesthetic

The design SHALL present a calm, neutral base (cream/white surfaces with near-black text) and use brand red and gold only as accents — for the page header band, primary actions, links, and emphasis. The design SHALL NOT use heavy holiday ornamentation, animation, or large saturated color fields that would make the interface feel flashy.

#### Scenario: Neutral base with accent color

- **WHEN** a content page is rendered
- **THEN** the page background and content surfaces are neutral (cream/white) with near-black text, and brand red/gold appear only on the header, primary buttons, links, and focused/active states

### Requirement: Global typographic and element baseline

The system SHALL apply a global baseline to common HTML elements so that unstyled markup still looks consistent. This SHALL set a readable system/sans-serif font stack, base font size and line height, heading scale, link styling, and sensible default margins, applied via element selectors so views need no per-page typography classes.

#### Scenario: Bare markup inherits the baseline

- **WHEN** a view renders headings, paragraphs, and links without any custom classes
- **THEN** they adopt the design system's font, sizing, heading scale, and link colors automatically

### Requirement: Shared page chrome

The application layout SHALL provide shared page chrome — a branded header band and a centered, width-constrained content container — so that every page, including pages added in the future, inherits the look without bespoke per-page layout styling.

#### Scenario: A new page inherits chrome automatically

- **WHEN** a new view is rendered through the application layout without adding any layout-specific markup
- **THEN** it appears inside the centered content container beneath the branded header band

#### Scenario: Content is width-constrained and centered

- **WHEN** a page is viewed on a wide screen
- **THEN** the main content is constrained to a comfortable maximum reading width and horizontally centered rather than spanning the full viewport

### Requirement: Styled common UI building blocks

The design system SHALL provide styles for the recurring UI building blocks already present in the application markup: flash messages (with success/error/notice variants), the main menu, index data tables, search controls, pagination controls, forms (the shared `_form` partials including labels, inputs, and validation/error states), buttons (primary and secondary/neutral variants), and the footer. New features SHALL reuse these building blocks and their class hooks rather than introducing ad-hoc equivalents.

#### Scenario: Flash messages are visually distinct by level

- **WHEN** a flash message of a given level (e.g. `notice` or `alert`) is shown
- **THEN** it is rendered with styling appropriate to that level (e.g. a positive tone for notice, an attention/error tone for alert) and is clearly separated from page content

#### Scenario: Data tables are legible

- **WHEN** the donors or donations index table is rendered
- **THEN** it has a styled header row, row separation, and comfortable cell padding consistent with the design tokens

#### Scenario: Forms and their states are styled

- **WHEN** a shared `_form` partial renders inputs, labels, and (when present) validation errors
- **THEN** inputs, labels, primary/secondary buttons, and error messaging are styled consistently using the design tokens

#### Scenario: Primary vs secondary actions are distinguishable

- **WHEN** a page presents a primary action (e.g. "Save", "New donor") alongside secondary links (e.g. "Back", "Cancel")
- **THEN** the primary action uses the brand-accent button style and secondary actions use a quieter neutral style

### Requirement: Centralized, framework-free implementation

The design system SHALL be implemented as plain CSS served by Propshaft, organized so that tokens and component styles live in dedicated stylesheet files linked in load order by the application layout (Propshaft does not concatenate or rewrite CSS `@import`, so each file is linked explicitly via `stylesheet_link_tag`). The change SHALL NOT introduce a new CSS framework, JavaScript styling dependency, or new gem.

#### Scenario: No new dependencies

- **WHEN** the change is implemented
- **THEN** no CSS/JS framework or gem is added, and the styles are delivered through the existing Propshaft asset pipeline

#### Scenario: Forward-looking convention is documented

- **WHEN** a developer begins a new feature after this change
- **THEN** documentation exists describing the available tokens and building-block classes and directs them to reuse these rather than writing ad-hoc styles
