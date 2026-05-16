## Context

The Access `DonorT` schema (see `docs/image002.png`) is the source of truth for donor record shape. We are recreating it in PostgreSQL with Rails-idiomatic names while preserving the original Access `DonorID` values so future bulk imports from Access can use IDs verbatim. `DonorT.CityTownID` references an Access `CityTownT` lookup that we also need to recreate; the prior change (`add-reference-tables`) deliberately deferred it, and we are picking it up now in the same change as the donors schema since donors cannot exist without it.

## Goals / Non-Goals

**Goals:**
- Create `city_towns` reference table (id, name) seeded with the rows from Access `CityTownT`, preserving original IDs
- Create `donors` table mirroring `DonorT` with Rails-idiomatic snake_case column names, preserving Access `DonorID` values
- Enforce data integrity at the database layer: NOT NULL FKs to `affiliates`, `categories`, `courtesy_titles`; nullable FK to `city_towns`
- Provide `Donor` and `CityTown` ActiveRecord models with associations to the existing reference-table models
- Provide fixtures and model tests that exercise the associations and the basic shape

**Non-Goals:**
- No donor controller, views, routes, or forms (out of scope; follow-up change)
- No collapsing `email1`/`email2` into a single `email + receipt_by_email` pair — we keep verbatim Access fidelity now; the collapse is a planned later change
- No address validation (postal code format, province enum, etc.); strings only
- No deduplication or "is this the same donor" logic
- No donation-side schema; that is a separate, downstream change

## Decisions

### Column naming and types

Map Access columns to Rails columns with snake_case, preserving meaning:

| Access | Rails | Type | Null? |
|---|---|---|---|
| DonorID | id | bigint (PK) | NO |
| AffiliateID | affiliate_id | bigint (FK) | NO |
| CategoryID | category_id | bigint (FK) | NO |
| CourtesyTitleID | courtesy_title_id | bigint (FK) | NO |
| FirstName | first_name | string | YES |
| Spouse | spouse | string | YES |
| LastName | last_name | string | YES |
| JobTitle | job_title | string | YES |
| Company | company | string | YES |
| AddressLine1 | address_line1 | string | YES |
| AddressLine2 | address_line2 | string | YES |
| CityTownID | city_town_id | bigint (FK) | YES |
| Province | province | string | YES |
| PostalCode | postal_code | string | YES |
| Phone | phone | string | YES |
| Email1 | email1 | string | YES |
| Email2 | email2 | string | YES |
| Notes | notes | text | YES |
| ZipCode | zip_code | string | YES |

**Alternative considered**: Renaming `email1`/`email2` to `receipt_email`/`contact_email`. Rejected for now — the project owner has flagged this for a deliberate later collapse into `email + receipt_by_email :boolean`, and renaming twice is more churn than keeping Access names verbatim through the import.

**Alternative considered**: Dropping `zip_code` (Manitoba-based Canadian charity). Rejected — kept for full Access fidelity; the field is cheap and a few legacy rows may use it.

### Nullability — names and addresses

`first_name`, `last_name`, `spouse`, `company`, etc. are all nullable. The `categories` reference table includes `Business`, `Government`, `Group/Organization`, `Individual`, `Other`, and `VOID Receipt` — only `Individual` rows are guaranteed to have a `last_name`, and `Business`/`Government` rows often have only a `company`. Database-level NOT NULL would reject valid records. Higher-level business rules (e.g., "individuals must have last_name") belong in the model, not in this change.

### Nullability — foreign keys

`affiliate_id`, `category_id`, `courtesy_title_id` are NOT NULL — every donor record in operational use has these three (explicit user decision). `city_town_id` is nullable — addresses are best-effort, and legacy Access rows may have missing CityTownIDs.

### ID preservation

Both `city_towns` and `donors` will preserve their Access integer IDs when seeded/imported, following the exact pattern from `add-reference-tables`: use `upsert_all` with explicit IDs, then advance the PostgreSQL sequence past the max seeded ID. For `donors`, no rows are seeded in this change — only the migration is added. The donor import is a separate change.

**Alternative considered**: Letting Rails generate fresh IDs and maintaining a mapping table for the Access import. Rejected — adds complexity for no benefit; Access IDs are stable and unique within their tables.

### Indexes

Migration-time indexes:
- `donors.affiliate_id` — Rails default via `references`
- `donors.category_id` — Rails default via `references`
- `donors.courtesy_title_id` — Rails default via `references`
- `donors.city_town_id` — Rails default via `references`
- `donors.last_name` — frequently used for donor lookup (reports, receipt mailings)
- `donors.company` — used for business-category lookup

No multi-column or partial indexes yet — those should be driven by actual query patterns once controllers exist.

### City_towns seed data — deferred

The seed rows for `city_towns` were not available at implementation time. By explicit decision during `/opsx:apply`, seeding is deferred to a follow-up change. `db/seeds.rb` carries a TODO marker where the seed block will go, and the `reference-tables` capability spec for `city_towns` asserts table shape only (not row contents). The donors table can still reference `city_towns` by FK because the table exists; legacy import scripts will populate it later.

### Model associations

```ruby
class Donor < ApplicationRecord
  belongs_to :affiliate
  belongs_to :category
  belongs_to :courtesy_title
  belongs_to :city_town, optional: true
end
```

Inverse `has_many :donors` is added to `Affiliate`, `Category`, `CourtesyTitle`, and `CityTown`. No validations beyond `belongs_to`'s default presence (which covers the NOT NULL FKs).

## Risks / Trade-offs

- **Empty city_towns seed at apply time** → Mitigated by the explicit handoff in this design: implementation should not proceed past the city_towns migration without seed data from the project owner.
- **Email1/Email2 will be renamed later** → Accepted; the planned collapse to `email + receipt_by_email :boolean` is documented in the proposal and tracked as a follow-up change.
- **Nullable name fields permit nonsense rows** → Acceptable for the import phase; model-level validations can be added in a follow-up change once category-driven rules are agreed.
- **No data-type validation on postal_code / phone** → Acceptable for Access fidelity; legacy data is already inconsistent and we don't want to reject imports.

## Migration Plan

1. Migration A — `create_city_towns` (id, name string NOT NULL)
2. Migration B — `create_donors` with all columns above; FKs added inline via `t.references … foreign_key: true`
3. `db/seeds.rb` — append idempotent seed block for `city_towns` (pending data from project owner)
4. Rollback: `bin/rails db:rollback STEP=2` drops `donors` then `city_towns`; seed rows go with the tables

## Open Questions

- None blocking. The single open item — the `city_towns` row list — is a data-collection step that happens between this proposal and `/opsx:apply`.
