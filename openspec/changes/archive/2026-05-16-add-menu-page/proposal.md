## Why

The signed-in landing page is currently a placeholder ("Christmas Cheer" heading plus a Sign out button). As soon as the donors feature is built the operator will need to navigate to it, and there is no entry point. A real menu page also gives us a place to surface the deployed commit hash and a link back to the repository — both useful for a single-volunteer app that has no other deployment dashboard, so the operator can confirm at a glance which build is live.

## What Changes

- Replace the contents of the authenticated root view with a menu page that lists the application's top-level destinations. For now the menu contains a single, disabled entry labeled "future: donors" (a placeholder, not a working link).
- Keep the Sign out control on the menu page so the only signed-in interaction today still works.
- Render a footer on the menu page (and any future pages that use the same layout) showing:
  - The short Git commit hash the application is running, linked to the corresponding commit on GitHub.
  - A separate link to the GitHub repository home page.
- Capture the Git commit SHA at Docker build time so it is available to the running container, with a development fallback that reads from the local working tree. Expose it through a single helper so views never shell out.

## Capabilities

### New Capabilities
- `app-menu`: The authenticated landing menu page (top-level navigation entry list) and the shared footer that displays build provenance (commit hash + GitHub links).

### Modified Capabilities
<!-- None. The authenticated root route already exists per app-bootstrap; this change replaces only the body of that view and adds a layout footer. No requirements in app-bootstrap need to change. -->

## Impact

- Replaces the body of `app/views/home/show.html.erb` and adds footer markup to `app/views/layouts/application.html.erb` (or a partial it renders).
- Adds a small helper / configuration object that returns the current commit SHA and the GitHub repository URL.
- Adds a `GIT_COMMIT_SHA` build ARG/ENV to `Dockerfile` and writes a `REVISION` file into the production image so the running container knows its own build.
- No database changes, no new gems, no changes to authentication, routes, or CI.
- No impact on the donors capability — the menu entry is a static placeholder, not a route.
