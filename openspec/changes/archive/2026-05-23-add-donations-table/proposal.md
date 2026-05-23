## Why

The `donors` table landed in the previous change, but a donor without donations is dead weight — every downstream feature (tax receipts, deposit reports, year-end totals, the Access import) needs a `donations` table to hang off. The Access `DonationT` schema is the source of truth and ready to recreate now.

## What Changes

- Add a `donations` table mirroring the Access `DonationT` schema with Rails-idiomatic snake_case column names, preserving Access `DonationID` values for future legacy imports
- Add a NOT NULL FK from `donations` to `donors`
- Add nullable bigint columns `source_id`, `payment_id`, `publication_id` **without** FK constraints — these correspond to Access `SourceID`/`PaymentID`/`PublicationID`, but the project owner has not yet confirmed which tables they refer to. The columns are shaped like FKs so a follow-up change can add the constraint in one line once the targets are confirmed
- Add an `app/models/donation.rb` model with `belongs_to :donor`
- Add `has_many :donations` to `Donor`
- Add fixtures and model tests covering the new association, NOT NULL enforcement, and money-column shape

## Capabilities

### New Capabilities
- `donations`: The core donation record (amount, eligible amount, dates, receipt-state flags, free-text fields) with a NOT NULL foreign key to the donor that made it

### Modified Capabilities

None. The `donors` capability gains an inverse `has_many :donations` but that does not change any spec-level requirement on `donors` itself.

## Impact

- New migration: one for `donations`
- New model: `Donation`; `Donor` gains `has_many :donations`
- No seed data — donations are import-only, not seeded
- No controllers, views, or routes — those are a follow-up change
- The `source_id` / `payment_id` / `publication_id` columns are deliberately unconstrained at the DB layer for now; a separate change will add the FKs once their target tables are confirmed
