# reference-tables

## Purpose

Six read-mostly lookup tables that donor and donation records reference by integer foreign key (seeded with exact values from the Access source database), plus a seventh `city_towns` table created without seed data for the donors FK to depend on.

## Requirements

### Requirement: affiliates table exists and is seeded

The database SHALL contain an `affiliates` table with columns `id` (integer primary key) and `name` (string, not null), seeded with the 7 rows from `AffiliateT`: BoissevainCC (1), BrandonCC (2), DeloraineCC (3), EOS_CC (4), MelitaCC (5), RiversCC (6), VirdenCC (7).

#### Scenario: Affiliates are queryable

- **WHEN** the application runs `Affiliate.order(:id).pluck(:name)`
- **THEN** the result is `["BoissevainCC", "BrandonCC", "DeloraineCC", "EOS_CC", "MelitaCC", "RiversCC", "VirdenCC"]`

#### Scenario: Affiliate IDs match Access originals

- **WHEN** `Affiliate.find(4)` is called
- **THEN** it returns the record with `name == "EOS_CC"`

### Requirement: categories table exists and is seeded

The database SHALL contain a `categories` table with columns `id` (integer primary key) and `name` (string, not null), seeded with the 6 rows from `CategoryT`: Business (1), Government (2), Group/Organization (3), Individual (4), Other (Specify in Notes) (5), VOID Receipt (6).

#### Scenario: Categories are queryable

- **WHEN** the application runs `Category.order(:id).pluck(:name)`
- **THEN** the result is `["Business", "Government", "Group/Organization", "Individual", "Other (Specify in Notes)", "VOID Receipt"]`

#### Scenario: Category IDs match Access originals

- **WHEN** `Category.find(4)` is called
- **THEN** it returns the record with `name == "Individual"`

### Requirement: courtesy_titles table exists and is seeded

The database SHALL contain a `courtesy_titles` table with columns `id` (integer primary key) and `title` (string, not null), seeded with the 11 rows from `CourtesyTitleT`: Dr. (1), Dr. & Mrs. (2), Fr. (3), Minister (4), Miss (5), Mr. (6), Mr. & Mrs. (7), Mrs. (8), Ms. (9), To Whom It May Concern (10), None (11).

#### Scenario: Courtesy titles are queryable

- **WHEN** the application runs `CourtesyTitle.order(:id).pluck(:title)`
- **THEN** the result is `["Dr.", "Dr. & Mrs.", "Fr.", "Minister", "Miss", "Mr.", "Mr. & Mrs.", "Mrs.", "Ms.", "To Whom It May Concern", "None"]`

#### Scenario: Courtesy title IDs match Access originals

- **WHEN** `CourtesyTitle.find(6)` is called
- **THEN** it returns the record with `title == "Mr."`

### Requirement: payments table exists and is seeded

The database SHALL contain a `payments` table with columns `id` (integer primary key) and `name` (string, not null), seeded with the 7 rows from `PaymentT`: Cash (1), Cheque (2), EFT (3), Gift Card (4), Gift in Kind (5), Other (Specify in Notes) (6), Square (7).

#### Scenario: Payments are queryable

- **WHEN** the application runs `Payment.order(:id).pluck(:name)`
- **THEN** the result is `["Cash", "Cheque", "EFT", "Gift Card", "Gift in Kind", "Other (Specify in Notes)", "Square"]`

#### Scenario: Payment IDs match Access originals

- **WHEN** `Payment.find(2)` is called
- **THEN** it returns the record with `name == "Cheque"`

### Requirement: publications table exists and is seeded

The database SHALL contain a `publications` table with columns `id` (integer primary key) and `name` (string, not null), seeded with the 9 rows from `PublicationT`: Anonymous (1), Business Name (2), Canadian Tire Customers (3), Fill the Bus-Safeway Customers (4), Fill the Bus-Sobeys West Customers (5), Name as Written (6), None (7), Other (Specify in Message) (8), UCT Bingo Players (9).

#### Scenario: Publications are queryable

- **WHEN** the application runs `Publication.order(:id).pluck(:name)`
- **THEN** the result is `["Anonymous", "Business Name", "Canadian Tire Customers", "Fill the Bus-Safeway Customers", "Fill the Bus-Sobeys West Customers", "Name as Written", "None", "Other (Specify in Message)", "UCT Bingo Players"]`

#### Scenario: Publication IDs match Access originals

- **WHEN** `Publication.find(3)` is called
- **THEN** it returns the record with `name == "Canadian Tire Customers"`

### Requirement: sources table exists and is seeded

The database SHALL contain a `sources` table with columns `id` (integer primary key) and `name` (string, not null), seeded with the 16 rows from `SourceT`: DeloraineCC (1), Benevity (2), CanadaHelps (3), Canadian Tire (4), CC Office (5), e-Transfer (6), Fill the Bus (7), Mail (8), Other (Specify in Notes) (9), PayPal (10), UCT Bingo (11), BoissevainCC (12), MelitaCC (13), RiversCC (14), EOS_CC (15), VirdenCC (16).

#### Scenario: Sources are queryable

- **WHEN** the application runs `Source.order(:id).pluck(:name)`
- **THEN** the result is `["DeloraineCC", "Benevity", "CanadaHelps", "Canadian Tire", "CC Office", "e-Transfer", "Fill the Bus", "Mail", "Other (Specify in Notes)", "PayPal", "UCT Bingo", "BoissevainCC", "MelitaCC", "RiversCC", "EOS_CC", "VirdenCC"]`

#### Scenario: Source IDs match Access originals

- **WHEN** `Source.find(8)` is called
- **THEN** it returns the record with `name == "Mail"`

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

### Requirement: Reference table seeds are idempotent

Running `bin/rails db:seed` more than once SHALL NOT duplicate any reference table rows or raise an error.

#### Scenario: Re-seeding is safe

- **WHEN** `bin/rails db:seed` is run a second time on a database that already has all reference rows
- **THEN** the command exits with status 0 and the row counts in each reference table remain unchanged

### Requirement: PK sequences are reset after seeding

After seeding, the PostgreSQL primary key sequence for each reference table SHALL be set to a value greater than the highest seeded ID so that future ActiveRecord inserts do not collide.

#### Scenario: New record gets a non-conflicting ID

- **WHEN** `Affiliate.create!(name: "TestCC")` is called after seeding
- **THEN** the new record receives an `id` greater than 7 (the highest seeded affiliate ID)
