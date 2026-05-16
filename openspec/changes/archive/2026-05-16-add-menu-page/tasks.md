## 1. Commit SHA capture

- [x] 1.1 Add `Rails.configuration.x.github_repo_url = "https://github.com/generalpf/ChristmasCheer"` default in `config/application.rb`.
- [x] 1.2 Add `app/models/app_revision.rb` (or `app/lib/app_revision.rb`) exposing `AppRevision.current_sha` and `AppRevision.short_sha`. Lookup order: `ENV["GIT_COMMIT_SHA"]`, then `Rails.root.join("REVISION")`, then `git rev-parse HEAD` (rescued), else `nil`. Memoize at boot.
- [x] 1.3 Add `ARG GIT_COMMIT_SHA` to the final stage of `Dockerfile`; write `RUN echo "$GIT_COMMIT_SHA" > /rails/REVISION` and set `ENV GIT_COMMIT_SHA=$GIT_COMMIT_SHA`.
- [x] 1.4 Update `config/deploy.yml` `builder.args` to pass `GIT_COMMIT_SHA: <%= %x(git rev-parse HEAD).strip %>` (or equivalent), and document this in a comment.
- [x] 1.5 Add a unit test for `AppRevision` covering: ENV wins over REVISION, REVISION wins over fallback, missing-everything returns `nil`.

## 2. Footer

- [x] 2.1 Add `app/helpers/application_helper.rb` methods `commit_link` and `github_repo_link`. `commit_link` renders the 7-char short SHA as a link to `…/commit/<full-sha>`, or the literal `unknown` (no link) when SHA is `nil`. `github_repo_link` renders the repo URL.
- [x] 2.2 Create `app/views/layouts/_footer.html.erb` with markup using the two helpers.
- [x] 2.3 Render the footer from `app/views/layouts/application.html.erb` inside `<body>`, after `<%= yield %>`.
- [x] 2.4 Add helper tests for both helpers, including the `unknown` fallback path.

## 3. Menu page

- [x] 3.1 Replace the body of `app/views/home/show.html.erb` with a heading and an unordered list of menu items. Add one item containing the literal text `future: donors` as a non-link (e.g., `<li>` with no `<a>`, marked visually as disabled — `<span aria-disabled="true">` is fine).
- [x] 3.2 Keep the existing Sign out `button_to` on the page.
- [x] 3.3 Add a controller test confirming `GET /` while authenticated returns 200, the response body contains `future: donors`, contains a sign-out form posting to `/session` with `_method=delete`, and does **not** contain `<a … future: donors`.
- [x] 3.4 Add a system test covering: sign in → land on menu page → see the placeholder entry and footer with a non-`unknown` SHA when running in-tree.

## 4. Verify

- [x] 4.1 Run `bin/rails test` and `bin/rails test:system`; all pass.
- [x] 4.2 Manually boot `bin/rails server`, sign in as the seeded operator, and confirm the menu page renders with the placeholder entry and the footer shows the current short SHA linking to the right GitHub commit.
- [x] 4.3 Build the production image locally with `docker build --build-arg GIT_COMMIT_SHA=$(git rev-parse HEAD) -t cc-test .` and run it long enough to confirm `/REVISION` is present and the footer renders correctly.
