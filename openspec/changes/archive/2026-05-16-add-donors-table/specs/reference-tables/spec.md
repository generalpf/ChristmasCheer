# reference-tables

## ADDED Requirements

### Requirement: city_towns table exists

The database SHALL contain a `city_towns` table with columns `id` (integer primary key) and `name` (string, not null). Seeding the table with the Access `CityTownT` rows is deferred to a follow-up change; this requirement is satisfied by the table's existence and shape.

#### Scenario: city_towns table is queryable

- **WHEN** the application runs `CityTown.connection.table_exists?("city_towns")`
- **THEN** the result is `true`

#### Scenario: city_towns has the expected columns

- **WHEN** the application runs `CityTown.columns.map(&:name).sort`
- **THEN** the result is `["id", "name"]`

#### Scenario: name is required

- **WHEN** the application attempts to insert a `city_towns` row with `name = NULL`
- **THEN** the database raises a NOT NULL violation
