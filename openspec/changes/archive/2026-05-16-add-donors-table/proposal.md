## Why

The donor record is the central entity the rest of the application (donations, tax receipts, reports) hangs off of. The six reference tables already exist; the remaining missing piece is the `donors` table itself and the `city_towns` lookup it depends on. Building these together unblocks the donations schema and every downstream feature.

## What Changes

- Add a `city_towns` reference table (id, name) modeled on the existing reference-tables pattern, with seeded rows preserving Access `CityTownT` IDs
- Add a `donors` table mirroring the Access `DonorT` schema with Rails-idiomatic snake_case column names, preserving Access `DonorID` values for future legacy imports
- Add NOT NULL foreign keys from `donors` to `affiliates`, `categories`, and `courtesy_titles`; nullable FK to `city_towns`
- Add an `app/models/city_town.rb` model and an `app/models/donor.rb` model with associations to the five reference tables
- Add fixtures and model tests covering the new associations and basic validations

## Capabilities

### New Capabilities
- `donors`: The core donor record (name, contact info, address, notes) with foreign keys into the affiliate / category / courtesy-title / city-town reference tables

### Modified Capabilities
- `reference-tables`: Adds a seventh reference table, `city_towns`, alongside the existing six

## Impact

- New migrations: one for `city_towns`, one for `donors`
- New models: `CityTown`, `Donor`; existing reference-table models gain `has_many :donors`
- `db/seeds.rb` gains an idempotent seed block for `city_towns` (seed rows supplied by the project owner)
- No controllers, views, or routes — those will land in a follow-up change
- The `app-bootstrap` and existing reference-table infrastructure are unchanged; this change layers on top of them
