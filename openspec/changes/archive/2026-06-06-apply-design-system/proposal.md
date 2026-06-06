## Why

The application's views currently ship with semantic class hooks (`flash`, `main-menu`, `donors-list`, etc.) but `app/assets/stylesheets/application.css` is empty, so every page renders as unstyled browser-default HTML. We need a consistent, functional-but-restrained visual design — drawn from the public Brandon-Westman Christmas Cheer brand — that applies to the screens already built and to every screen built going forward, so the app looks like part of the organization rather than a raw prototype.

## What Changes

- Introduce a single, centralized design system implemented as plain CSS (no new front-end framework), built on design tokens (CSS custom properties) for color, typography, spacing, and surfaces.
- Adopt the organization's brand palette, sampled from the live site: Christmas red `#ED1C24`, deep brick red `#822D23`, gold accents `#FFCB05` / `#B0A986`, near-black text `#2F2F2E`, cream/off-white surfaces `#EAEAE8` and white, and neutral grey `#727272`. The aesthetic is deliberately understated — brand color used as accents on a calm neutral base, not a flashy holiday theme.
- Apply the design to the existing UI by styling the class hooks already present in the markup: the page shell/layout, flash messages, the main menu (`home/show`), donor and donation index tables, search/pagination controls, and the shared `_form` partials and footer.
- Establish a shared page chrome (header band + content container) in the layout so new pages inherit the look automatically without per-page styling.
- Document conventions (token names, class-naming approach, where global vs. component styles live) so future features stay consistent.

## Capabilities

### New Capabilities
- `visual-design`: A centralized brand-aligned visual design system — design tokens, global element/typography baseline, shared page chrome, and styling for the common UI building blocks (flash, menu, tables, forms, buttons, pagination, footer) — that all current and future views conform to.

### Modified Capabilities
<!-- None. The behavior/requirements of donor-crud, donation-crud, app-menu, etc. are unchanged; only presentation is added. -->

## Impact

- `app/assets/stylesheets/` — new design-token and component stylesheet(s); `application.css` becomes the manifest that pulls them in.
- `app/views/layouts/application.html.erb` and `app/views/layouts/_footer.html.erb` — add shared page chrome wrapper(s) and confirm class hooks.
- Existing views (`home/show`, `donors/*`, `donations/*`, `sessions/new`, `passwords/*`) — minor class-hook additions only where needed; no behavioral/logic changes.
- No new gems, no JS framework, no database changes. Propshaft serves the CSS as-is.
- Sets a forward-looking convention: every new view must use the established tokens/classes rather than introducing ad-hoc styles.
