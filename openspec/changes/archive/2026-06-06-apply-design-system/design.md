## Context

This is a Rails 8 app using Propshaft for assets and an importmap-based JS setup — no Sprockets, no Node bundler, no CSS framework. Views already carry semantic class hooks (`flash flash--<level>`, `main-menu`, `menu-item`, `donors-list`, `donors-search`, `donors-pagination`, the `_form` partials, `_footer`) but `app/assets/stylesheets/application.css` is an empty manifest, so everything renders as browser-default HTML.

The reference brand is the public Brandon-Westman Christmas Cheer site (a Wix site). Its theme palette was sampled directly from the site's CSS custom properties:

- `--color_3` = `#ED1C24` — Christmas red (primary accent)
- `--color_18/19` = `#822D23` — deep brick red (headers/emphasis)
- `--color_5` = `#FFCB05` — gold; muted gold seen in use `#B0A986` / `#CDC6A4`
- `--color_15` = `#2F2F2E` — near-black text
- `--color_12` = `#EAEAE8` — light cream/off-white surface
- `--color_13`/`--color_14` = `#8C8C8B` / `#5E5E5D` — greys

The user's directive: "functional but not flashy," applied to existing UI and everything built going forward.

## Goals / Non-Goals

**Goals:**
- A single, centralized, token-driven CSS design system in plain CSS served by Propshaft.
- Brand-aligned but restrained visuals: neutral base, brand color as accents.
- Shared page chrome in the layout so future pages inherit the look for free.
- Styling for all existing class hooks; minimal markup changes (add hooks only where missing).
- Documented conventions so future work stays consistent.

**Non-Goals:**
- No new CSS/JS framework, gem, or build step.
- No redesign of information architecture, navigation structure, or page content.
- No behavioral/logic changes to controllers, models, or routes.
- No dark mode, theming switcher, or holiday animations.
- Not pixel-matching the Wix site — we borrow the palette and tone, not the layout.

## Decisions

### Plain CSS with custom-property tokens, no framework
The app already avoids a front-end toolchain; adding Tailwind/Bootstrap would mean a build step or a large vendored file and conflicts with the "not flashy / functional" goal. Plain CSS organized around `:root` custom properties (`--color-*`, `--space-*`, `--font-*`, `--radius-*`) gives a single source of truth, works natively with Propshaft, and keeps the surface area small.
- *Alternative considered:* Tailwind via the `tailwindcss-rails` gem — rejected: introduces a dependency and a utility-class style that contradicts the existing semantic-class markup.
- *Alternative considered:* Inline styles per view — rejected: not centralized, can't be reused by future pages.

### File organization
Split styles into purpose files under `app/assets/stylesheets/` and pull them in through the `application.css` manifest using Propshaft `@import` / require ordering:
- `tokens.css` — `:root` custom properties (color, type, spacing, radius, shadow).
- `base.css` — element baseline (reset-ish, body, headings, links, tables, form elements).
- `layout.css` — page chrome: header band, content container, footer.
- `components.css` — flash, menu, buttons, tables (index lists), search, pagination, forms/validation.

Loading order matters (tokens → base → layout → components) so later, more specific rules win predictably.

### Shared page chrome lives in the layout
Add a branded header band and a centered `<main class="container">` wrapper in `app/views/layouts/application.html.erb`, wrapping `<%= yield %>`. This is the key lever for "applies to everything we build going forward" — new views need zero layout code to look right. Flash rendering moves inside the container region; footer keeps its partial.

### Semantic classes over utility classes
Keep and extend the existing semantic hooks already in the markup. Where a hook is missing for something we must style (e.g. button variants, primary action), add a small, named class (`btn`, `btn--primary`, `btn--secondary`) rather than utilities. This matches the codebase's existing idiom.

### Restraint as an explicit rule
Brand red/gold are confined to: header band, primary buttons, links, and focus/active states. Surfaces stay cream/white, text near-black, borders light grey. This is encoded in the spec ("Restrained, functional aesthetic") so future contributors don't drift toward a flashy theme.

## Risks / Trade-offs

- **Propshaft import mechanics** → Propshaft doesn't preprocess `@import` the way Sprockets concatenated `require` directives. Mitigation: verify whether to use multiple `<%= stylesheet_link_tag %>` entries, plain CSS `@import` in `application.css`, or a single file; pick whichever Propshaft serves correctly and standardize on it. Confirm by loading a page locally.
- **Class-hook drift** → A few views may reference classes that don't exist yet, or need a hook added (e.g. buttons). Mitigation: audit each existing view (`home/show`, `donors/*`, `donations/*`, `sessions/new`, `passwords/*`) and reconcile class names between markup and CSS as part of the work.
- **Accessibility/contrast** → Brand red on cream or gold text can fail WCAG contrast. Mitigation: use deep brick red `#822D23` (not the bright `#ED1C24`) for text-on-light and reserve bright red for solid-fill buttons with white text; spot-check contrast.
- **"Looks flashy" subjectivity** → Mitigation: keep accents minimal, no animation; if in doubt, lean neutral. Easy to dial color up later, harder to walk back.
- **Low rollback risk** → Change is additive CSS + layout wrapper; reverting the commit restores the prior (unstyled) state with no data or behavioral impact.
