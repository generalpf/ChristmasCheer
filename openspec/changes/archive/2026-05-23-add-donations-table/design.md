## Context

The Access `DonationT` schema (see `docs/image003.png`) is the source of truth for the donation record shape. We are recreating it in PostgreSQL with Rails-idiomatic names while preserving the original Access `DonationID` values so a future bulk Access import can use them verbatim.

`DonationT` references four other Access tables: `DonorT` (the donor — table now exists as `donors`), `SourceT`, `PaymentT`, and `PublicationT`. The project owner has confirmed that `donations.donor_id` should be NOT NULL with a real FK. The other three — `source_id`, `payment_id`, `publication_id` — are deferred: the columns ship as nullable `bigint` with no FK constraint, because the actual target tables have not yet been confirmed. (There are existing `sources`, `payments`, `publications` reference tables in this project, but it has not yet been verified that the Access fields point at those.)

This change layers cleanly on top of `add-donors-table`. No other table or model is modified beyond adding the inverse `has_many :donations` to `Donor`.

## Goals / Non-Goals

**Goals:**
- Create `donations` table mirroring `DonationT` with Rails-idiomatic snake_case column names, preserving Access `DonationID` values
- Enforce data integrity at the database layer: NOT NULL FK to `donors`; NOT NULL money columns with default 0; NOT NULL receipt booleans defaulting to false
- Ship `source_id` / `payment_id` / `publication_id` as nullable bigint columns without FK constraints, so a follow-up change can add the constraint when targets are confirmed
- Provide a `Donation` ActiveRecord model with `belongs_to :donor` and an inverse `has_many :donations` on `Donor`
- Provide fixtures and model tests that exercise the association and assert the basic table shape

**Non-Goals:**
- No donation controller, views, routes, or forms (follow-up change)
- No FK constraint on `source_id`, `payment_id`, or `publication_id` (follow-up change once targets are confirmed)
- No receipt-state state machine — the four `receipt_*` booleans are stored verbatim from Access; modeling them as a status enum is a future cleanup
- No donation-import logic; this change is schema only
- No validations beyond `belongs_to`'s default presence on `donor`

## Decisions

### Column naming and types

Map Access columns to Rails columns with snake_case, preserving meaning:

| Access | Rails | Type | Null? | Default |
|---|---|---|---|---|
| DonationID | id | bigint (PK) | NO | — |
| DonorID | donor_id | bigint (FK) | NO | — |
| Donation | amount | decimal(12,2) | NO | 0 |
| EligibleAmt | eligible_amount | decimal(12,2) | NO | 0 |
| SourceID | source_id | bigint | YES | — |
| PaymentID | payment_id | bigint | YES | — |
| TransactionReference | transaction_reference | string | YES | — |
| PublicationID | publication_id | bigint | YES | — |
| Message | message | string | YES | — |
| DonationDate | donation_date | date | YES | — |
| ReceiptDate | receipt_date | date | YES | — |
| DepositDate | deposit_date | date | YES | — |
| CReceiptNum | c_receipt_num | integer | YES | — |
| ReceiptNum | receipt_num | string | YES | — |
| ReceiptRequired | receipt_required | boolean | NO | false |
| ReceiptPending | receipt_pending | boolean | NO | false |
| ReceiptProcessed | receipt_processed | boolean | NO | false |
| ReceiptReplaced | receipt_replaced | boolean | NO | false |
| Notes | notes | text | YES | — |

Plus standard Rails `created_at` / `updated_at` timestamps.

**Money columns** — `amount` and `eligible_amount` are `decimal(12,2)` (Postgres `numeric(12,2)`), the standard money pattern in Rails. NOT NULL with default `0` because every donation has an amount and the default keeps legacy import safe even if a row is missing the field. `12,2` gives us up to 9,999,999,999.99 — vastly more than any plausible donation.

**Money column rename** — Access uses bare `Donation`/`EligibleAmt`. We rename to `amount`/`eligible_amount` because (a) `donations.donation` is awkward to read and write, and (b) Rails idiom is `amount` for money columns. The mapping is preserved in this design doc and in import scripts.

**Date columns** — Access uses `Date/Time` for all three; the underlying data is dates only (no time component is meaningful for donation/receipt/deposit dates), so we use `date` rather than `datetime`. All three are nullable: a donation may be entered before its receipt or deposit date is known.

**Boolean columns** — All four `receipt_*` are NOT NULL with default `false`. Access `Yes/No` is effectively NOT NULL with default false; this matches.

**CReceiptNum** — The leading `C` in `CReceiptNum` is preserved as `c_receipt_num`. We don't yet know what the `C` stands for ("Charity"? "Cancelled"?); renaming requires knowing.

**Alternative considered** — storing money as integer cents (`amount_cents :integer`). Rejected for now: the project has no money-handling code yet, decimal is the simplest correct option, and the conversion to cents (or a Money gem) can come later if we find a reason.

### Foreign keys

- `donor_id` — NOT NULL, `foreign_key: true` to `donors(id)`. A donation without a donor is nonsense.
- `source_id`, `payment_id`, `publication_id` — nullable `bigint`, **no FK constraint**. The columns are named like FKs so the eventual `add_foreign_key` migration is a one-line add.

The columns are not declared via `t.references` because `t.references … foreign_key: false` would still build an index. We may not want indexes on those columns until we know what they reference and how they're queried. They're plain `t.bigint`, nullable, no index.

**Alternative considered** — adding FK constraints to the existing `sources`, `payments`, `publications` reference tables now. Rejected per project owner: those tables exist with the same name shape, but it has not been verified that the Access `SourceID`/`PaymentID`/`PublicationID` actually point at those. Adding FKs prematurely could block legacy import if there's a mismatch.

### ID preservation

The `donations` table preserves Access `DonationID` values when the legacy import lands. No rows are seeded in this change — only the migration is added. The import itself is a separate change and will use the same pattern as the reference tables: `upsert_all` with explicit IDs, then advance the sequence.

### Indexes

Migration-time indexes:
- `donations.donor_id` — Rails default via `t.references … foreign_key: true`
- `donations.donation_date` — for date-range reporting (year-end totals, monthly reports). This is the dominant donation-side query pattern.
- `donations.receipt_required` partial index where `receipt_required = true AND receipt_processed = false` — for the "donations awaiting a receipt" workflow that drives the receipt-printing UI. **Deferred** to the controller change; we don't know exact predicate yet.

For now we ship only the two indexes (`donor_id`, `donation_date`). No multi-column or partial indexes — those should be driven by actual query patterns once controllers exist.

**Alternative considered** — indexing `receipt_num` for receipt-lookup. Rejected for now: we don't have a UI flow that does receipt lookup by string. Add when the UI lands.

### Model associations

```ruby
class Donation < ApplicationRecord
  belongs_to :donor
end

class Donor < ApplicationRecord
  # ...existing belongs_to...
  has_many :donations, dependent: :restrict_with_exception
end
```

`dependent: :restrict_with_exception` because deleting a donor that has donations would orphan tax-receipt history. If the operator really wants to delete a donor with donations, they need to handle the donations first — the exception is the right signal.

**Alternative considered** — `dependent: :destroy`. Rejected: donations are receipt-relevant and should never be silently cascaded away.

No validations on `Donation` beyond `belongs_to`'s default presence (which covers the NOT NULL `donor_id`). Business rules ("if `receipt_required` then `receipt_num` after processing") belong in a later change.

## Risks / Trade-offs

- **`source_id` / `payment_id` / `publication_id` unconstrained at DB layer** → Accepted. The columns can hold any bigint, including IDs that point nowhere. Mitigation: legacy import will populate them only from Access where they were valid; a follow-up change adds the FK constraint once the target tables are confirmed.
- **Money as decimal not cents** → Accepted. If we later move to a Money gem or integer cents, it's a single migration; no current code reads the field.
- **Four receipt booleans rather than a single status enum** → Accepted. Matches Access verbatim, defers a modeling decision that's hard to make without seeing real data. Cleanup is a separate change.
- **`donation_date` is `date` not `datetime`** → Accepted. Loses sub-day ordering on the same date, but Access stored time-zero values anyway and donation-of-record is a date concept.
- **Renaming Access `Donation` → `amount`** → Accepted. Slight friction for someone cross-referencing Access docs, but the readability win and Rails-idiom win are worth it. The mapping is documented here and will be re-documented in the import change.

## Migration Plan

1. Migration — `create_donations` with all columns above; `donor_id` via `t.references :donor, null: false, foreign_key: true`; `source_id` / `payment_id` / `publication_id` as plain `t.bigint`, nullable, no index; index on `donation_date`.
2. Rollback: `bin/rails db:rollback` drops `donations`. No seed data to back out.

## Open Questions

- **What does the `C` in `CReceiptNum` stand for?** → Not blocking; column ships as `c_receipt_num` and can be renamed in a follow-up once known.
- **What tables do `SourceID`, `PaymentID`, `PublicationID` actually reference in Access?** → Not blocking; columns ship without FK constraints, follow-up change adds them.
