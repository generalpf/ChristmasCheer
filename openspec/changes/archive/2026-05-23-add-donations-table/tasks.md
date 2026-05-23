## 1. donations table migration

- [x] 1.1 Generate migration `create_donations` with all columns from design.md
- [x] 1.2 Use `t.references :donor, null: false, foreign_key: true` for `donor_id`
- [x] 1.3 Add `t.decimal :amount, precision: 12, scale: 2, null: false, default: 0` and the same for `eligible_amount`
- [x] 1.4 Add `t.bigint :source_id`, `t.bigint :payment_id`, `t.bigint :publication_id` — nullable, no FK, no index
- [x] 1.5 Add `t.string :transaction_reference`, `t.string :message`, `t.string :receipt_num` — all nullable
- [x] 1.6 Add `t.date :donation_date`, `t.date :receipt_date`, `t.date :deposit_date` — all nullable
- [x] 1.7 Add `t.integer :c_receipt_num` — nullable
- [x] 1.8 Add four booleans `receipt_required`, `receipt_pending`, `receipt_processed`, `receipt_replaced` — `null: false, default: false`
- [x] 1.9 Add `t.text :notes` — nullable
- [x] 1.10 Add `t.timestamps`
- [x] 1.11 Add `add_index :donations, :donation_date` in the same migration
- [x] 1.12 Run `bin/rails db:migrate` and verify `db/schema.rb` reflects the donations table with all columns, the donor FK, and both indexes (`donor_id`, `donation_date`)

## 2. Models and associations

- [x] 2.1 Create `app/models/donation.rb` with `belongs_to :donor`
- [x] 2.2 Add `has_many :donations, dependent: :restrict_with_exception` to `app/models/donor.rb`

## 3. Fixtures and tests

- [x] 3.1 Add `test/fixtures/donations.yml` with at least: one donation with all required fields only (defaults take over), one with a `source_id`/`payment_id`/`publication_id` populated to bogus values (to prove they're accepted without FK), one with `receipt_required: true, receipt_pending: true`, and one referencing a donor that already exists in `donors.yml`
- [x] 3.2 Write a model test for `Donation` covering: `belongs_to :donor` returns the expected donor; missing `donor_id` fails save (`belongs_to` validation); `source_id`/`payment_id`/`publication_id` accept arbitrary bigints
- [x] 3.3 Write a model test for `Donor` covering: `donor.donations` returns associated donations; `donor.destroy` on a donor with donations raises `ActiveRecord::DeleteRestrictionError`
- [x] 3.4 Write a spec-coverage test that asserts the `donations` table column set, the `donor_id` and `donation_date` indexes, and the absence of FK constraints on `source_id` / `payment_id` / `publication_id` (per the donations spec scenarios)
- [x] 3.5 Run `bin/rails test` and confirm all tests pass

## 4. Validation pass

- [x] 4.1 Run `bin/rails db:reset` from a clean state and confirm migrate → seed exits 0
- [x] 4.2 In `bin/rails console`: confirm `Donation.create!(donor: Donor.first)` saves with `amount: 0`, `eligible_amount: 0`, all four `receipt_*` false
- [x] 4.3 In `bin/rails console`: confirm inserting `donor_id: 9999` via raw SQL (`ActiveRecord::Base.connection.execute`) raises a DB-level FK violation
- [x] 4.4 In `bin/rails console`: confirm `Donation.create!(donor: Donor.first, source_id: 9999, payment_id: 9999, publication_id: 9999)` saves successfully (no FK constraint exists)
- [x] 4.5 Run `bin/rails test` one final time
