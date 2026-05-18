## Context

The `donors` table and its four reference-table FKs (`affiliates`, `categories`, `courtesy_titles`, `city_towns`) are in place from the earlier `add-donors-table` and `add-reference-tables` changes. The `Donor` model declares `belongs_to` associations for all four (with `city_town` optional). No model-level validations exist beyond what `belongs_to` provides. The authenticated home page (`HomeController#show`) is a menu that lists `future: donors` as a deliberately disabled placeholder.

The app is a single-volunteer Rails 8 omakase install — Propshaft, Importmap, Hotwire (Turbo + Stimulus), the omakase `Authentication` concern. Authentication is already required by `ApplicationController`, so any new controller is authenticated by default. The donor data set is small: the Access source database has on the order of a few thousand donor rows, and the operator works with one record at a time. There is one user; no roles, no audit log, no soft-delete.

There are no donations or receipts in the system yet, so destroying a donor today is unconstrained. That changes once donations land — when it does, donations will likely point at donor with `restrict_with_exception` (matching the reference-table pattern) and the controller's destroy path will start surfacing `ActiveRecord::DeleteRestrictionError`. We design the destroy flow with that future in mind but do not block on it.

## Goals / Non-Goals

**Goals:**
- A complete, navigable web UI for donor records using the standard Rails RESTful resource pattern (`resources :donors`).
- Search by last-name or company keyword on the index — the two operations the operator actually does to find a donor.
- Form fields cover every column on the `donors` table (excluding the legacy `zip_code` field — see Decisions).
- Reference FKs render as `<select>` dropdowns sourced from the seeded reference tables, sorted by display name.
- Validation errors come back inline on the form, not as 500s or raw DB exceptions.
- Replace the `future: donors` placeholder with a working link so the menu page reflects current capability.

**Non-Goals:**
- Donations, receipts, or any data model beyond donors.
- CSV import or export (the legacy Access import is a separate one-shot data migration).
- Bulk operations (delete-many, merge-duplicates) — the operator handles one record at a time.
- Audit trail, soft-delete, or revision history.
- Advanced search: address-field search, date filters, fuzzy matching, full-text. Last-name and company are enough.
- Inline creation of reference rows (e.g., creating a new `city_town` from inside the donor form). Reference tables stay read-only for this change.
- Pagination libraries (Kaminari, Pagy). A small inline LIMIT/OFFSET helper is enough at this volume.
- A separate `/admin` namespace. The whole app is operator-only; the donor routes live at the top level next to `home#show`.

## Decisions

### Decision: Top-level `resources :donors`, not namespaced under `/admin`

Every page in this app requires authentication. There is no public surface to namespace away from. `resources :donors` at the top level keeps URLs short (`/donors/123`) and avoids a `Admin::DonorsController` indirection that would buy nothing.

Alternative considered: nest everything under `namespace :admin`. Rejected because (1) there is no non-admin counterpart, and (2) future capabilities (donations, reports) will live in the same flat space, so adding `/admin` now would force a rename of `home#show` to `admin/home#show` too.

### Decision: One `DonorsController` with the seven standard REST actions

Plain Rails-omakase controller (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`). Strong params method `donor_params`. Reference dropdowns loaded into instance variables in `new` and `edit` (and re-loaded on validation failure for re-render).

No service object, no form object — at this scope they would be ceremony. If a future change adds non-trivial creation logic (e.g., dedupe-on-create, address normalization), revisit then.

### Decision: Pagination is inline LIMIT/OFFSET, page size 50

The Access export is a few thousand donor rows. At 50 per page that is ~40-80 pages — finite and walkable, especially with search. We expose a `page` query param, default 1, and render plain "Previous / page X of Y / Next" controls.

Alternative considered: Kaminari or Pagy. Rejected because adding a gem for a single index page when the underlying scrollback is small is over-spend; the inline implementation is ~10 lines of controller/view code.

### Decision: Search is a single `q` param, case-insensitive ILIKE on `last_name` OR `company`

The operator looks up donors by name (individuals) or company (businesses). Combining both into one box lets them type either without thinking about which field to use. We use Postgres `ILIKE '%q%'` against the two columns that already have indexes (`index_donors_on_last_name`, `index_donors_on_company`). Both indexes are b-tree, so they will not be used for the prefixless `%q%` pattern, but at this row count a sequential scan is fast — we will not introduce trigram indexes prematurely.

Alternative considered: separate inputs for last name, company, email, address. Rejected as more UI for less use. If a search miss becomes a complaint, we widen the column list before changing the input shape.

Alternative considered: pg_trgm + `gin` index for prefixless ILIKE. Rejected as premature for this row count; revisit if index scans become measurable.

### Decision: Render reference FKs with `collection_select` from sorted reference data

`Affiliate`, `Category`, `CourtesyTitle`, and `CityTown` are sorted alphabetically by their display column (`name` or `title`) and passed to the form partial as instance variables. `city_town` includes `include_blank: true`; the other three do not, so the operator must pick one (matching the NOT NULL DB constraint).

The reference rows are seeded with stable IDs that match the Access originals (see `reference-tables` spec). The form uses Rails-default ID values; we do not surface the legacy IDs anywhere in the UI.

### Decision: Add an identification validation, not a per-field validation

The `donors` table allows every name and company column to be null (so the legacy Access import succeeds even for sparse rows), but creating a brand-new donor with no usable identifier would be a data-entry mistake. We add a single custom validation that attaches to `:base`: a donor is valid only if `company` is present, OR if both `first_name` AND `last_name` are present. A bare first name (or a bare last name) with no company is not enough — those rows would be ambiguous in any address-block or receipt context the operator uses next. The error message reads `"must have both a first and last name, or a company"`.

Rationale: this matches the two real shapes a donor takes in the source data — an individual (first + last name) or a non-personal entity (company / organization). It rejects half-filled rows without blocking legitimate sparse cases where one branch is satisfied.

Existing fixture rows that store only `first_name` (e.g., `oddball_other` with `first_name: Anonymous`) are loaded by Rails via direct INSERT and bypass model validations, so the validation does not retroactively invalidate already-stored data. Editing such a row through the UI will, however, surface the validation error until the operator adds a last name or a company — that is the intended behaviour.

Email format, phone format, and postal-code format are deliberately not validated. The Access source data has imperfect values for all three and we do not want to reject them on edit. If validation becomes useful later, format normalization is a separate change.

### Decision: Leave the `zip_code` column out of the form (keep it in the schema)

`donors.zip_code` is a legacy column carried over from the Access schema for import fidelity (most rows have it null; a few have US ZIPs alongside Canadian postal codes). It is not something the operator should be editing in 2026 — for Canadian addresses we use `postal_code`. We do not show or accept `zip_code` in the new/edit form. The column stays in the table for historical lookup; the show page renders it as a read-only field when non-blank so the operator can see imported values, but there is no way to set it through the UI.

Alternative considered: drop the column. Rejected — this change is UI-only; a schema change for a column that does no harm is out of scope. If the operator confirms the imported ZIPs are uninteresting, a future migration can drop it.

### Decision: Destroy uses `button_to ... method: :delete` with a Turbo confirm

Standard Rails-omakase destroy pattern. No JS, no custom modal. The confirm text reads `"Delete this donor? This cannot be undone."`. On success we redirect to the index with a flash; on `ActiveRecord::DeleteRestrictionError` (which cannot happen today but will once donations land) we catch the exception, render the show page with a flash explaining the donor has dependent records, and do not delete.

Alternative considered: soft-delete via a `deleted_at` column. Rejected for now — there is no recoverable state and no audit consumer that needs the historical row. Revisit if donations introduce one.

### Decision: Menu link updates the `app-menu` capability

The proposal removes the `future: donors` placeholder and replaces it with a real link. That changes the existing scenario in `openspec/specs/app-menu/spec.md` from "entry is not a hyperlink with text `future: donors`" to "entry is a hyperlink to `/donors` with text `Donors`". Because this changes published spec behavior, we record it as a `MODIFIED Requirement` against `app-menu` in this change's spec deltas (full text copied per the modify workflow).

Other `app-menu` requirements (footer, sign-out availability, commit-SHA accessor, etc.) are untouched.

## Risks / Trade-offs

- **[Risk]** ILIKE `%q%` against `last_name` / `company` will sequentially scan once the table grows past the small-data zone or the operator types short queries with no early match. **Mitigation**: monitor; if it becomes noticeable, add a `pg_trgm` GIN index in a follow-up change. At expected volume it is a non-issue.
- **[Risk]** No validation of email/phone/postal-code format means the form accepts garbage. **Mitigation**: this matches the legacy data already in the table — the operator is the only writer and is also the proofreader. Adding format validation later is a non-breaking change.
- **[Risk]** Destroy is irreversible and has no undo. **Mitigation**: hard confirm in the UI ("This cannot be undone"); the operator has DB-level recovery from backups. A future donations capability will introduce FK restriction that further protects donors with associated activity.
- **[Trade-off]** Inline pagination instead of a gem keeps the dependency surface small but means we re-invent "page X of Y" in one place. Acceptable at this scope; if a second paginated index appears (donations index next quarter), extract a small helper rather than retrofitting a gem.
- **[Trade-off]** The `zip_code` field is read-only in the UI but still in the schema. Slight surface area for confusion ("why can't I edit this?"). Mitigated by labeling it `Legacy ZIP (read-only)` on the show page and not surfacing it at all on the form.

## Migration Plan

No data migration. Deployment is a normal code release:

1. Merge the change. Rails picks up the new routes, controller, views, and validations on next boot.
2. No DB changes — nothing to run against production.
3. Rollback: revert the merge commit. Nothing persists on the data side.

The legacy `zip_code` column remains untouched, so prior imports and any future schema-cleanup change are independent.

## Open Questions

- Should the donor show page link to a (future) donations list for that donor? Out of scope for this change; flagged so the next change can decide whether to back-link from a fresh donations index or add it to this show page then.
