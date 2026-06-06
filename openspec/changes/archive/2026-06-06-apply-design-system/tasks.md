## 1. Asset pipeline setup

- [x] 1.1 Confirm how Propshaft serves multiple stylesheets (plain CSS `@import` in `application.css` vs. multiple `stylesheet_link_tag` entries); pick one approach and note it
- [x] 1.2 Create empty stylesheet files: `tokens.css`, `base.css`, `layout.css`, `components.css` under `app/assets/stylesheets/`
- [x] 1.3 Wire them into `application.css` (or the layout) in load order: tokens → base → layout → components
- [x] 1.4 Load any page locally and confirm all four files are fetched with HTTP 200

## 2. Design tokens

- [x] 2.1 Define `:root` color tokens in `tokens.css`: brand red `#ED1C24`, deep brick red `#822D23`, gold `#FFCB05`, muted gold `#B0A986`, near-black text `#2F2F2E`, cream surface `#EAEAE8`, white, grey `#727272`
- [x] 2.2 Add semantic aliases (e.g. `--color-text`, `--color-bg`, `--color-surface`, `--color-accent`, `--color-link`, `--color-border`) mapping onto the brand tokens
- [x] 2.3 Add typography tokens (font stack, base size, line height, heading scale) and spacing/radius/shadow tokens

## 3. Element baseline

- [x] 3.1 In `base.css`, add a light reset (box-sizing, margin normalization) and set `body` background/text/font from tokens
- [x] 3.2 Style headings (h1–h3 scale), paragraphs, and default margins
- [x] 3.3 Style links (default + hover/focus) using accent/link tokens, ensuring contrast on light surfaces (use deep brick red for text-weight color)
- [x] 3.4 Add baseline styling for `table`, form `input`/`select`/`textarea`, and `label`

## 4. Shared page chrome

- [x] 4.1 In `app/views/layouts/application.html.erb`, add a branded header band and wrap `<%= yield %>` in a centered, width-constrained `<main class="container">`
- [x] 4.2 Move flash rendering inside the container region and confirm markup still iterates `flash.each`
- [x] 4.3 In `layout.css`, style the header band (brand color), the centered container (max-width + horizontal centering), and the footer (`_footer` partial)
- [x] 4.4 Verify a page with no custom layout markup (e.g. a future/blank view) inherits chrome correctly

## 5. Component styles

- [x] 5.1 Style flash messages with `flash--notice`/`flash--alert` (and any other levels) variants in `components.css`
- [x] 5.2 Style the main menu (`main-menu`, `menu-item`, `menu-item__label`) on `home/show`
- [x] 5.3 Add button classes (`btn`, `btn--primary`, `btn--secondary`) and apply primary style to primary actions, neutral style to secondary links
- [x] 5.4 Style index data tables (`donors-list`, `donations` index table): header row, row separation, cell padding
- [x] 5.5 Style search controls (`donors-search`) and pagination (`donors-pagination`, including `.disabled` state)
- [x] 5.6 Style the shared `_form` partials: labels, inputs, submit buttons, and validation/error message states

## 6. Reconcile existing views

- [x] 6.1 Audit `home/show`, `donors/*`, `donations/*`, `sessions/new`, `passwords/*` for class hooks that the CSS expects; add missing hooks (e.g. button variants) with minimal markup changes
- [x] 6.2 Verify no controller/model/route logic changed — presentation only

## 7. Verification & documentation

- [x] 7.1 Run the app and visually confirm: menu, donors index + search + pagination, donor form, donations index, a donation form, a flash message, and the footer all render with the design applied
- [x] 7.2 Spot-check color contrast for text on brand/gold backgrounds (legibility)
- [x] 7.3 Run `bin/rubocop` and the test suite to confirm nothing is broken
- [x] 7.4 Add a short conventions doc (e.g. in `docs/` or a comment block in `tokens.css`) listing available tokens and building-block classes, directing future features to reuse them
