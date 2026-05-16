## Context

The Access database has six lookup tables that donor and donation records reference by integer ID. We are recreating them in PostgreSQL with Rails-idiomatic names and seeding them from the exact Access data captured in `docs/ref-*.png`. Because future migrations will import legacy Access records (donors, donations), preserving the original integer IDs ensures foreign keys in the imported data point to the correct rows without a translation layer.

## Goals / Non-Goals

**Goals:**
- Six migration-created tables: `affiliates`, `categories`, `courtesy_titles`, `payments`, `publications`, `sources`
- Idempotent seed blocks that insert the canonical rows while preserving the original Access IDs
- Minimal ActiveRecord models (class + table_name only where Rails can't infer it)

**Non-Goals:**
- No UI, controllers, or admin CRUD for these tables at this stage
- No `city_towns` table — the donor schema will handle the CityTownID lookup separately
- No soft-delete or versioning on reference rows

## Decisions

### Table and column naming

Use plural snake_case table names without the Access `T` suffix. Each table has two columns: `id` (integer primary key) and `name` (string, not null). `courtesy_titles` uses `title` as the value column instead of `name` to avoid ambiguity with a person's name.

**Alternative considered**: Keeping a generic `value` column name across all tables. Rejected — `name` reads more naturally for affiliates, categories, etc., and `title` is the right domain term for a salutation.

### ID preservation

Seed rows are inserted with explicit IDs matching the Access originals using `ActiveRecord::Base.connection.execute` raw SQL or `insert_all` with the `id` field included, followed by a sequence reset. This means future donor/donation import scripts can use Access IDs verbatim.

**Alternative considered**: Let Rails generate IDs and build a mapping table. Rejected — adds unnecessary complexity for a known, stable dataset.

### Seed idempotency

Seed blocks use `upsert_all` (Rails 6+) on the `id` column so re-running `db:seed` is safe. The PostgreSQL sequence is advanced past the max seed ID after insert to prevent future Rails-generated IDs from colliding.

## Risks / Trade-offs

- **Sequence collision** → Mitigated by resetting each table's PK sequence to `max(id) + 1` at the end of each seed block.
- **Schema divergence if Access data changes** → These tables are treated as stable; any additions go through a new migration + seed upsert.

## Migration Plan

1. Run the six `create_table` migrations (one per table, in a single migration file is fine)
2. Run `db:seed` to populate rows
3. Rollback: `db:rollback` drops all six tables; seed data goes with them
