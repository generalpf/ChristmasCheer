# donors

## Purpose

The core donor record — names, contact information, address — with foreign keys into the affiliate, category, courtesy-title, and city-town reference tables. Mirrors the Access `DonorT` schema and preserves Access `DonorID` values for legacy import.

## Requirements

### Requirement: donors table exists with the documented columns

The database SHALL contain a `donors` table with these columns: `id` (bigint primary key), `affiliate_id` (bigint, NOT NULL, FK to `affiliates`), `category_id` (bigint, NOT NULL, FK to `categories`), `courtesy_title_id` (bigint, NOT NULL, FK to `courtesy_titles`), `city_town_id` (bigint, nullable, FK to `city_towns`), `first_name` (string, nullable), `spouse` (string, nullable), `last_name` (string, nullable), `job_title` (string, nullable), `company` (string, nullable), `address_line1` (string, nullable), `address_line2` (string, nullable), `province` (string, nullable), `postal_code` (string, nullable), `phone` (string, nullable), `email1` (string, nullable), `email2` (string, nullable), `notes` (text, nullable), `zip_code` (string, nullable), plus standard `created_at` / `updated_at` timestamps.

#### Scenario: Table has the expected columns

- **WHEN** the application runs `Donor.columns.map(&:name).sort`
- **THEN** the result includes `address_line1`, `address_line2`, `affiliate_id`, `category_id`, `city_town_id`, `company`, `courtesy_title_id`, `created_at`, `email1`, `email2`, `first_name`, `id`, `job_title`, `last_name`, `notes`, `phone`, `postal_code`, `province`, `spouse`, `updated_at`, `zip_code`

#### Scenario: Operational FKs are NOT NULL

- **WHEN** the application attempts `Donor.create!(affiliate_id: nil, category_id: 1, courtesy_title_id: 6)`
- **THEN** the database raises a NOT NULL violation on `affiliate_id`

#### Scenario: city_town_id is nullable

- **WHEN** the application creates a `Donor` with `city_town_id: nil` and all required FKs populated
- **THEN** the record is saved successfully and `donor.city_town_id` is `nil`

### Requirement: donors table enforces foreign keys

The database SHALL enforce referential integrity on every donor foreign key via PostgreSQL `FOREIGN KEY` constraints to `affiliates(id)`, `categories(id)`, `courtesy_titles(id)`, and `city_towns(id)`.

#### Scenario: Bogus affiliate_id is rejected

- **WHEN** the application attempts to insert a donor with `affiliate_id = 9999` (no matching `affiliates` row)
- **THEN** the database raises a foreign-key violation

#### Scenario: Bogus city_town_id is rejected

- **WHEN** the application attempts to insert a donor with `city_town_id = 9999` (no matching `city_towns` row)
- **THEN** the database raises a foreign-key violation

### Requirement: donors table has lookup indexes

The `donors` table SHALL include database indexes on `affiliate_id`, `category_id`, `courtesy_title_id`, `city_town_id`, `last_name`, and `company` to support the lookup patterns used by donor and donation reports.

#### Scenario: Expected indexes exist

- **WHEN** the application runs `ActiveRecord::Base.connection.indexes("donors").map(&:columns).flatten.sort.uniq`
- **THEN** the result includes `affiliate_id`, `category_id`, `city_town_id`, `company`, `courtesy_title_id`, and `last_name`

### Requirement: Donor model exposes associations to reference tables

The `Donor` ActiveRecord model SHALL declare `belongs_to` associations for `affiliate`, `category`, `courtesy_title`, and `city_town` (optional), and each of those reference-table models SHALL declare the inverse `has_many :donors`.

#### Scenario: Donor returns its associated records

- **GIVEN** a saved `Donor` with `affiliate_id = 1`, `category_id = 4`, `courtesy_title_id = 6`, `city_town_id = nil`
- **WHEN** the application accesses `donor.affiliate.name`, `donor.category.name`, `donor.courtesy_title.title`, and `donor.city_town`
- **THEN** the first three return the matching reference-table names, and `donor.city_town` is `nil`

#### Scenario: Reference table returns its donors

- **GIVEN** at least one donor with `affiliate_id = 1`
- **WHEN** the application accesses `Affiliate.find(1).donors`
- **THEN** the result includes that donor
