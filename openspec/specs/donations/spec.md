# donations Specification

## Purpose
TBD - created by archiving change add-donations-table. Update Purpose after archive.
## Requirements
### Requirement: donations table exists with the documented columns

The database SHALL contain a `donations` table with these columns: `id` (bigint primary key), `donor_id` (bigint, NOT NULL, FK to `donors`), `amount` (decimal(12,2), NOT NULL, default 0), `eligible_amount` (decimal(12,2), NOT NULL, default 0), `source_id` (bigint, nullable, no FK constraint), `payment_id` (bigint, nullable, no FK constraint), `transaction_reference` (string, nullable), `publication_id` (bigint, nullable, no FK constraint), `message` (string, nullable), `donation_date` (date, nullable), `receipt_date` (date, nullable), `deposit_date` (date, nullable), `c_receipt_num` (integer, nullable), `receipt_num` (string, nullable), `receipt_required` (boolean, NOT NULL, default false), `receipt_pending` (boolean, NOT NULL, default false), `receipt_processed` (boolean, NOT NULL, default false), `receipt_replaced` (boolean, NOT NULL, default false), `notes` (text, nullable), plus standard `created_at` / `updated_at` timestamps.

#### Scenario: Table has the expected columns

- **WHEN** the application runs `Donation.columns.map(&:name).sort`
- **THEN** the result includes `amount`, `c_receipt_num`, `created_at`, `deposit_date`, `donation_date`, `donor_id`, `eligible_amount`, `id`, `message`, `notes`, `payment_id`, `publication_id`, `receipt_date`, `receipt_num`, `receipt_pending`, `receipt_processed`, `receipt_replaced`, `receipt_required`, `source_id`, `transaction_reference`, `updated_at`

#### Scenario: donor_id is NOT NULL

- **WHEN** the application attempts to insert a donation row with `donor_id = NULL` (bypassing model validations)
- **THEN** the database raises a NOT NULL violation on `donor_id`

#### Scenario: Money columns default to zero and are NOT NULL

- **WHEN** the application inserts a donation row supplying only `donor_id` (bypassing model validations)
- **THEN** `amount` and `eligible_amount` are persisted as `0` and the row is saved successfully

#### Scenario: Receipt booleans default to false and are NOT NULL

- **WHEN** the application inserts a donation row supplying only `donor_id` (bypassing model validations)
- **THEN** `receipt_required`, `receipt_pending`, `receipt_processed`, and `receipt_replaced` are all persisted as `false`

#### Scenario: Deferred FK columns are nullable bigints

- **WHEN** the application creates a `Donation` with `source_id: nil`, `payment_id: nil`, `publication_id: nil` and a valid `donor_id`
- **THEN** the record is saved successfully and all three fields are `nil`

### Requirement: donations table enforces the donor foreign key

The database SHALL enforce referential integrity on `donations.donor_id` via a PostgreSQL `FOREIGN KEY` constraint to `donors(id)`. The columns `source_id`, `payment_id`, and `publication_id` SHALL NOT have FK constraints in this change — they are deferred until the target tables are confirmed.

#### Scenario: Bogus donor_id is rejected

- **WHEN** the application attempts to insert a donation with `donor_id = 9999` (no matching `donors` row)
- **THEN** the database raises a foreign-key violation

#### Scenario: Arbitrary source_id is accepted

- **WHEN** the application creates a `Donation` with `source_id = 9999` and a valid `donor_id`
- **THEN** the record is saved successfully (no FK constraint exists on `source_id`)

### Requirement: donations table has lookup indexes

The `donations` table SHALL include database indexes on `donor_id` (for per-donor donation lookup) and `donation_date` (for date-range reporting).

#### Scenario: Expected indexes exist

- **WHEN** the application runs `ActiveRecord::Base.connection.indexes("donations").map(&:columns).flatten.sort.uniq`
- **THEN** the result includes `donor_id` and `donation_date`

### Requirement: Donation model belongs to a donor

The `Donation` ActiveRecord model SHALL declare `belongs_to :donor`, and the `Donor` model SHALL declare `has_many :donations, dependent: :restrict_with_exception`.

#### Scenario: Donation returns its donor

- **GIVEN** a saved `Donation` with `donor_id` set to an existing donor's id
- **WHEN** the application accesses `donation.donor`
- **THEN** the matching `Donor` record is returned

#### Scenario: Donor returns its donations

- **GIVEN** a donor with at least one associated donation
- **WHEN** the application accesses `donor.donations`
- **THEN** the result includes that donation

#### Scenario: Deleting a donor with donations raises

- **GIVEN** a donor with at least one associated donation
- **WHEN** the application calls `donor.destroy`
- **THEN** an `ActiveRecord::DeleteRestrictionError` is raised and the donor is not deleted

