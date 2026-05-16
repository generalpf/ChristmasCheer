## Why

The donor and donation schemas (coming next) reference six lookup tables — affiliates, categories, courtesy titles, payment methods, publications, and sources — that must exist before those foreign keys can be defined. Creating them now, seeded with the exact values from the Access database, keeps migration fidelity high and lets subsequent changes build on a stable reference layer.

## What Changes

- Add six reference tables to the PostgreSQL schema, each named in Rails convention (plural, snake_case, no `T` suffix)
- Seed each table with the exact records from the Access source data
- Provide ActiveRecord models for each table so the rest of the app can reference them by association

## Capabilities

### New Capabilities

- `reference-tables`: Six read-mostly lookup tables (affiliates, categories, courtesy_titles, payments, publications, sources) with seed data matching the Access originals

### Modified Capabilities

## Impact

- New migrations and models; no existing code is changed
- `db/seeds.rb` gains idempotent seed blocks for each reference table
- The `app-bootstrap` infrastructure is unchanged; this change layers on top of it
