# Design system

A small, framework-free CSS design system drawn from the Brandon-Westman
Christmas Cheer brand. The look is deliberately **functional, not flashy**: a
calm cream/white base with near-black text, and brand red/gold used only as
accents (header band, primary buttons, links, focus states).

**When building any new screen, reuse the tokens and classes below — do not add
ad-hoc colors, sizes, or one-off component styles.**

## Where things live

Stylesheets in `app/assets/stylesheets/`, loaded in this order by the
application layout via `stylesheet_link_tag` (Propshaft does not concatenate or
rewrite CSS `@import`, so each file is linked explicitly):

1. `tokens.css` — design tokens (CSS custom properties). The source of truth.
2. `base.css` — element/typography baseline for bare HTML.
3. `layout.css` — shared page chrome (header band, `.container`, footer).
4. `components.css` — reusable building blocks.

`application.css` is documentation only and is **not** linked.

## Tokens (use these, don't hard-code)

Colors via semantic aliases: `--color-text`, `--color-text-muted`,
`--color-bg`, `--color-surface`, `--color-border`, `--color-accent` (deep brick
red `#822D23`, contrast-safe for text on light), `--color-accent-strong`
(bright red `#ED1C24`, solid-fill buttons only), `--color-link`,
`--color-header-bg`, `--color-accent-gold` (muted gold, borders/accents).
Feedback tones: `--color-notice-*`, `--color-alert-*`.

Also: `--font-sans`, `--font-size-*`, `--space-1..8`, `--radius`, `--shadow*`,
`--container-max`.

## Page chrome (automatic)

Every page rendered through `layouts/application.html.erb` automatically gets
the branded header band and a centered, width-constrained `<main class="container">`.
New views need **no** layout markup — just write the page body.

## Building blocks

- **Flash**: rendered by the layout as `<div class="flash flash--notice">` /
  `flash--alert`. Controllers just set `flash[:notice]` / `flash[:alert]`.
- **Buttons**: `.btn` / `.btn--primary` (solid brand red) for primary actions;
  `.btn--secondary` (quiet outline) for secondary. Plain links read as quiet
  secondary actions. `input[type="submit"]` and `button` get the primary style
  automatically.
- **Tables**: index lists (e.g. `.donors-list`, `.donations-list`) get a styled
  header row, row separation, and hover. Bare `<table>` already inherits a
  legible baseline.
- **Forms**: wrap each control in `<div class="field">`; use `<div class="actions">`
  for the submit row. Error summaries use `.{model}-form__errors`.
- **Search / filter**: `.donors-search` / `.donations-filter` lay controls out
  inline. **Pagination**: `.donors-pagination` / `.donations-pagination` with a
  `.disabled` span for unavailable steps.
- **Detail pages**: `<dl class="donor-detail">` / `.donation-detail` for
  labeled record views.

## Adding to the system

Need a value that isn't a token? Add a token to `tokens.css` rather than
inlining it. Need a new component? Add a named, semantic class to
`components.css` (match the existing BEM-ish naming) instead of utilities or
inline styles, and keep brand color as an accent on a neutral base.
