## Context

The authenticated root route already exists (`root "home#show"` rendered by `HomeController#show`) but the view contains only an `<h1>` and a Sign out button. With donors and reporting features about to land, the operator needs a navigation surface. The single-volunteer use case means we don't need a fancy nav bar — a vertical list of destinations on the landing page is enough.

The repository runs Rails 8 with the omakase defaults (Propshaft, Importmap, Hotwire). Production deploys via Kamal from a Dockerfile that copies the full repo (including `.git/`) into a build stage but produces a slim final image. The final image does **not** keep a `.git` directory by default, so we need to bake the commit SHA in at build time.

Repository GitHub URL: `https://github.com/generalpf/ChristmasCheer` (from `git remote -v`).

## Goals / Non-Goals

**Goals:**
- One-screen menu page as the signed-in landing experience.
- A single, easily-extended list of menu entries — adding the real "donors" link later is just swapping a placeholder for a route helper.
- Always-present footer showing build provenance (short commit hash linked to its GitHub commit page, plus a link to the repo).
- Deterministic, in-process commit SHA lookup. No shelling out to `git` on every request.

**Non-Goals:**
- Top nav bars, breadcrumbs, sidebars, or any chrome beyond the menu list and footer.
- Per-user customization or role-based menu filtering — there is one user.
- A real donors route, controller, or view. This change leaves a placeholder only.
- Changing authentication, sessions, or the existing sign-out flow.
- Showing build metadata other than the commit SHA (no build date, no branch name).
- Asset/CSS work beyond what's needed to make the page legible — visual polish is a follow-up.

## Decisions

### Decision: Reuse `HomeController#show` rather than introducing a `MenusController`

The route `root "home#show"` already exists and is what the user lands on after sign-in. Renaming the controller would be churn with no benefit; the "home" semantically *is* the menu for this app. We replace the view body in place.

Alternative considered: add `resource :menu, only: :show` and a `MenusController`. Rejected because it creates two URLs (`/` and `/menu`) that mean the same thing and forces a redirect or a duplicate route, neither of which is worth it for a single-page menu.

### Decision: Menu items rendered from an in-view array, not a database or config file

The menu has one item today. Hard-coding the list in the view (or a small helper) keeps the change minimal and gives a clear single edit point when donors lands. A `MenuItem` PORO or a YAML-backed config would be over-engineering for two entries.

When donors lands, the placeholder entry becomes a route-helper-driven link in the same array. No abstraction needed until there is a third or fourth menu item.

### Decision: Capture the commit SHA at Docker build time via a build ARG + REVISION file

The Dockerfile gets a new `ARG GIT_COMMIT_SHA` in the final stage and writes that value to `/rails/REVISION`. At app boot, a small accessor (`AppRevision.current_sha`) reads, in order:

1. `ENV["GIT_COMMIT_SHA"]` if present (lets Kamal/CI inject without rebuilding).
2. The contents of `Rails.root.join("REVISION")` if present.
3. `git rev-parse HEAD` shelled out **once** at boot, only if a `.git` directory is present (development fallback).
4. `nil` — view renders the literal `unknown` in place of the hash.

The lookup runs once at boot and the result is memoized in a constant/`Rails.configuration.x.app_revision`. Views never call out to Git.

Kamal will need to pass `--build-arg GIT_COMMIT_SHA=$(git rev-parse HEAD)` from `config/deploy.yml`'s `builder.args` section. That's a config-file edit, not code.

Alternatives considered:
- **Read `.git/HEAD` at runtime in production** — rejected because the slim image strips `.git`.
- **Bundle the SHA into `Rails.configuration` via an env var only (no REVISION file)** — workable but the REVISION file is a well-known Heroku/Capistrano convention and survives even if env vars are reset by the runner. Keeping both gives us belt-and-suspenders with very little code.
- **Run `git rev-parse HEAD` on every request** — rejected: forks a process per request, breaks in containers with no `.git`.

### Decision: GitHub URL lives in `Rails.configuration.x.github_repo_url`, defaulted in `config/application.rb`

Hard-coding `https://github.com/generalpf/ChristmasCheer` directly in the view is fine, but pulling it into config gives one tidy place to change if we ever fork or rename, and lets the helper compose `…/commit/<sha>` without string-mashing in ERB. Defaulted in `application.rb` (not an initializer) so it loads before any view rendering.

No env var override is needed today — if it becomes useful, add it later.

### Decision: Footer lives in the shared layout, not the home view

The footer should appear on every authenticated page once we add more (donors, reports). Putting it in `app/views/layouts/application.html.erb` (or a partial rendered from there) means we write it once. The menu page is the first beneficiary; future pages get it for free.

### Decision: Helper module for footer rendering

Add `ApplicationHelper#commit_link` and `#github_repo_link` returning safe HTML, called from a `_footer.html.erb` partial. Keeps the layout readable and gives a single seam for testing the "unknown" fallback.

## Risks / Trade-offs

- **[Risk]** Kamal builds may run without `GIT_COMMIT_SHA` being passed in, leaving production showing `unknown`. **Mitigation**: document the `--build-arg` requirement in `config/deploy.yml` comments and the deploy section of the README; the fallback is a visible `unknown` in the footer, which is loud enough to notice.
- **[Risk]** Shelling out to `git rev-parse` at boot in development could fail in unusual setups (worktrees, submodules). **Mitigation**: wrap in a `begin/rescue StandardError`, return `nil`, and let the footer say `unknown`. No exceptions reach the request cycle.
- **[Trade-off]** Hard-coding the GitHub URL in `application.rb` couples the app to a specific repository name. Acceptable: this is an internal charity app with one owner and there is no plan to fork.
- **[Trade-off]** The menu items live in the view rather than a model. If menu length grows past ~5 items or we need per-route enabled/disabled logic, we'll refactor to a small `MenuItem` value object then.

## Migration Plan

No data migration. Deployment notes:

1. Build the production image with `--build-arg GIT_COMMIT_SHA=$(git rev-parse HEAD)` (Kamal `builder.args`).
2. Deploy via Kamal as normal. The new footer should display the deployed SHA. If it shows `unknown`, the build ARG is missing — fix `deploy.yml` and rebuild.
3. Rollback is a normal Kamal rollback; no schema or data changes to revert.
