## 1. Migration

- [x] 1.1 Generate a single migration `create_reference_tables` that creates all six tables: `affiliates` (id, name), `categories` (id, name), `courtesy_titles` (id, title), `payments` (id, name), `publications` (id, name), `sources` (id, name) — all string columns NOT NULL
- [x] 1.2 Run `bin/rails db:migrate` and verify `db/schema.rb` reflects all six tables

## 2. Models

- [x] 2.1 Create `app/models/affiliate.rb`
- [x] 2.2 Create `app/models/category.rb`
- [x] 2.3 Create `app/models/courtesy_title.rb`
- [x] 2.4 Create `app/models/payment.rb`
- [x] 2.5 Create `app/models/publication.rb`
- [x] 2.6 Create `app/models/source.rb`

## 3. Seeds

- [x] 3.1 Add idempotent seed block for `affiliates` (7 rows, explicit IDs, sequence reset after)
- [x] 3.2 Add idempotent seed block for `categories` (6 rows, explicit IDs, sequence reset after)
- [x] 3.3 Add idempotent seed block for `courtesy_titles` (11 rows, explicit IDs, sequence reset after)
- [x] 3.4 Add idempotent seed block for `payments` (7 rows, explicit IDs, sequence reset after)
- [x] 3.5 Add idempotent seed block for `publications` (9 rows, explicit IDs, sequence reset after)
- [x] 3.6 Add idempotent seed block for `sources` (16 rows, explicit IDs, sequence reset after)
- [x] 3.7 Run `bin/rails db:seed` and verify row counts match spec; run it a second time and confirm idempotency

## 4. Tests

- [x] 4.1 Write a model test that verifies the seeded row counts and spot-checks specific IDs for each table (per spec scenarios)
- [x] 4.2 Run `bin/rails test` and confirm all tests pass
