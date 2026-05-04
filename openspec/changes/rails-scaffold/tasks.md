## 1. Toolchain & Repo Prep

- [x] 1.1 Confirm latest stable Ruby 3.x patch and write it to `.ruby-version`
- [x] 1.2 Confirm latest Rails 8.x patch and note version for use in `rails new`
- [x] 1.3 Verify PostgreSQL 16 is installed locally (`postgres --version`); document install for macOS/Linux in README later
- [x] 1.4 Update root `.gitignore` to include `log/`, `tmp/`, `storage/`, `.env*`, `config/master.key`, `config/credentials/*.key`

## 2. Generate Rails Application

- [x] 2.1 Run `rails new . --database=postgresql --skip-bundle --force` from the repo root (note: `--force` allows overwriting non-conflicting files; review diff for `.gitignore` and any docs collisions before staging)
- [x] 2.2 Run `bundle install`
- [x] 2.3 Run `bin/rails db:create db:migrate`
- [x] 2.4 Verify `bin/rails server` boots and `/` returns the default Rails welcome page
- [ ] 2.5 Commit the `rails new` output as a single commit

## 3. Authentication Scaffold

- [x] 3.1 Run `bin/rails generate authentication`
- [x] 3.2 Run `bin/rails db:migrate` to apply the users/sessions migrations
- [x] 3.3 Verify generated routes via `bin/rails routes | grep -E "(session|password)"`
- [x] 3.4 Confirm `bcrypt` is in `Gemfile.lock` and `app/models/user.rb` declares `has_secure_password`
- [x] 3.5 Confirm `db/seeds.rb` does NOT create any users (remove any defaults if present)
- [ ] 3.6 Commit the auth scaffold

## 4. Placeholder Home Page

- [x] 4.1 Generate `HomeController` with an `index` action: `bin/rails g controller Home index`
- [x] 4.2 Replace the generated view with a minimal page showing "Brandon-Westman Christmas Cheer — Coming Soon"
- [x] 4.3 Set `root "home#index"` in `config/routes.rb`
- [x] 4.4 Delete the default `public/index.html` if Rails 8 generated one (it does not by default; verify)
- [x] 4.5 Add an integration test asserting GET `/` returns 200 and includes the placeholder text
- [ ] 4.6 Commit

## 5. Lint & Security Tooling

- [x] 5.1 Confirm `rubocop-rails-omakase` is in the `:development` Gemfile group (Rails 8 includes it by default; verify)
- [x] 5.2 Confirm `brakeman` is present (Rails 8 includes it by default; verify)
- [x] 5.3 Add `erb_lint` to the `:development` group and create `.erb-lint.yml` with the recommended Rails preset
- [x] 5.4 Run `bin/rubocop -a` and `bin/erb_lint --lint-all -a` to autocorrect any default-template offenses
- [x] 5.5 Run `bin/brakeman --no-pager` and resolve or document any warnings (expected: zero on a stock app)
- [ ] 5.6 Commit lint/scan baseline

## 6. bin/setup and Developer Ergonomics

- [x] 6.1 Replace generated `bin/setup` with a script that: checks for Postgres, runs `bundle install`, runs `bin/rails db:prepare`, runs `bin/rails assets:clobber` (no-op if no assets yet), and prints next-steps
- [x] 6.2 Verify `bin/setup` exits non-zero with a clear message when `pg_isready` fails
- [x] 6.3 Verify `bin/dev` is present (Rails 8 ships it) and boots the app on port 3000
- [ ] 6.4 Commit

## 7. CI Workflow

- [x] 7.1 Create `.github/workflows/ci.yml` with three jobs: `lint` (rubocop + erb_lint), `scan` (brakeman), `test` (Minitest with a `services: postgres:16` container)
- [x] 7.2 Use `ruby/setup-ruby@v1` with `bundler-cache: true` for gem caching
- [x] 7.3 Configure the test job to set `DATABASE_URL` pointing at the service container and run `bin/rails db:test:prepare && bin/rails test`
- [x] 7.4 Trigger workflow on `push` to default branch and on `pull_request`
- [ ] 7.5 Push to a feature branch, open a draft PR, confirm all three jobs go green
- [ ] 7.6 Iterate on YAML until green; commit final version

## 8. README and Final Hygiene

- [x] 8.1 Replace the stock `README.md` with a project-specific version covering: project description, prerequisites (Ruby version, PostgreSQL 16), `bin/setup`, `bin/dev`, `bin/rails test`, link to `openspec/` for the change workflow
- [x] 8.2 Verify `git status` is clean and no master keys / `.env` files are tracked
- [x] 8.3 Run the full local check: `bin/setup && bin/rubocop && bin/brakeman --no-pager && bin/rails test && bin/dev` (kill bin/dev after confirming root URL renders)
- [ ] 8.4 Confirm CI is green on the PR
- [x] 8.5 Run `openspec validate rails-scaffold --strict` and resolve any issues

## 9. Spec Verification

- [x] 9.1 Walk every requirement in `specs/app-foundation/spec.md` and confirm there is evidence (a passing test, a green CI run, or a present file) that satisfies each scenario
- [x] 9.2 Walk every requirement in `specs/authentication/spec.md` and confirm there is evidence for each scenario (sign-in test, sign-out test, password reset test, public home page, empty seeds)
- [x] 9.3 If any scenario lacks evidence, write the missing test or fix the missing piece before marking the change apply-complete
