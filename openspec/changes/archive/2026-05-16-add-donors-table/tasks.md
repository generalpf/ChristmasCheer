## 1. city_towns reference table

- [x] 1.1 Generate migration `create_city_towns` with columns `id` and `name` (string, NOT NULL)
- [x] 1.2 Run `bin/rails db:migrate` and verify `db/schema.rb` includes `city_towns`
- [x] 1.3 Create `app/models/city_town.rb`
- [x] 1.4 Seed data deferred to a follow-up change (decision recorded in design.md)
- [x] 1.5 Add a TODO marker in `db/seeds.rb` indicating where the `city_towns` seed block will go
- [x] 1.6 Run `bin/rails db:seed` and confirm it still exits 0 (existing reference tables unchanged; `city_towns` remains empty)

## 2. donors table

- [x] 2.1 Generate migration `create_donors` with all columns from design.md, FK references for `affiliate_id`, `category_id`, `courtesy_title_id` (NOT NULL) and `city_town_id` (nullable), `foreign_key: true` on each
- [x] 2.2 Add indexes on `donors.last_name` and `donors.company` in the same migration (FK indexes come from `t.references`)
- [x] 2.3 Run `bin/rails db:migrate` and verify `db/schema.rb` reflects the donors table with all columns, FKs, and indexes

## 3. Models and associations

- [x] 3.1 Create `app/models/donor.rb` with `belongs_to :affiliate`, `belongs_to :category`, `belongs_to :courtesy_title`, `belongs_to :city_town, optional: true`
- [x] 3.2 Add `has_many :donors` to `Affiliate`, `Category`, `CourtesyTitle`, and `CityTown` models

## 4. Fixtures and tests

- [x] 4.1 Add `test/fixtures/city_towns.yml` with a handful of rows (using IDs that don't collide with the seed range)
- [x] 4.2 Add `test/fixtures/donors.yml` with at least one fixture per category type, including one with a `nil` city_town
- [x] 4.3 Write a model test for `Donor` covering: associations return the expected reference records; NOT NULL FKs (`affiliate`, `category`, `courtesy_title`) are validated by `belongs_to`; `city_town` association is optional
- [x] 4.4 Write a model test for `CityTown` covering: model loads, `has_many :donors` works (seed-count check dropped — seeding deferred)
- [x] 4.5 Write a spec-coverage test that asserts `donors` table column shape and required indexes exist (per the donors spec scenarios)
- [x] 4.6 Run `bin/rails test` and confirm all tests pass

## 5. Validation pass

- [x] 5.1 Run `bin/rails db:reset` from a clean state and confirm the full sequence (migrate → seed) exits 0
- [x] 5.2 Confirm `Donor.create!` with a missing required FK raises (Rails validation + DB-level FK both verified)
- [x] 5.3 Confirm `Donor` with `affiliate_id: 9999` or `city_town_id: 9999` raises a DB-level FK violation (bypassing validation)
- [x] 5.4 Run `bin/rails test` one final time
