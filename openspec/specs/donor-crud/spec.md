# donor-crud

## Purpose

HTTP surface and view layer for listing, searching, viewing, creating, editing, and deleting donor records, including the model-level validations that the create/edit forms surface. All donor routes are operator-only — authentication comes from `ApplicationController`'s `Authentication` concern.

## Requirements

### Requirement: Authenticated donor index lists donors

The application SHALL expose `GET /donors` as an authenticated route that renders an HTML list of donor records ordered alphabetically by last name (with company as the secondary sort for rows whose `last_name` is blank), paginated 50 rows per page, and including a link to each donor's show page.

#### Scenario: Unauthenticated request is redirected

- **WHEN** an unauthenticated client requests `GET /donors`
- **THEN** the response is a 302 redirect to the sign-in page
- **AND** no donor data appears in the response body

#### Scenario: Authenticated index renders donors

- **GIVEN** the database contains at least one donor record with `last_name = "Smith"`
- **WHEN** an authenticated operator requests `GET /donors`
- **THEN** the response has HTTP status 200
- **AND** the response body contains the text `Smith`
- **AND** the response body contains a hyperlink whose `href` is `/donors/<that-donor-id>`

#### Scenario: Index orders by last name then company

- **GIVEN** donors `(last_name: "Adams", company: nil)`, `(last_name: "Zeller", company: nil)`, and `(last_name: nil, company: "Acme Co")` exist
- **WHEN** an authenticated operator requests `GET /donors?page=1`
- **THEN** the rendered rows place `Adams` before `Zeller`
- **AND** the row for `Acme Co` is grouped with the `nil` last-name records in a stable order

#### Scenario: Index paginates at 50 per page

- **GIVEN** the database contains 60 donor records
- **WHEN** an authenticated operator requests `GET /donors?page=1`
- **THEN** the response body contains at most 50 donor rows
- **AND** the response body contains a link or control to navigate to `page=2`

### Requirement: Donor index supports keyword search

The donor index SHALL accept a query parameter `q` and, when present, restrict the rendered list to donors whose `last_name` OR `company` matches the query case-insensitively as a substring (PostgreSQL `ILIKE '%q%'`).

#### Scenario: Search matches last name

- **GIVEN** donors with `last_name = "Smith"` and `last_name = "Jones"` exist
- **WHEN** an authenticated operator requests `GET /donors?q=smit`
- **THEN** the response body contains `Smith`
- **AND** the response body does not contain `Jones`

#### Scenario: Search matches company

- **GIVEN** a donor with `company = "Acme Industries"` and `last_name = nil` exists
- **WHEN** an authenticated operator requests `GET /donors?q=acme`
- **THEN** the response body contains `Acme Industries`

#### Scenario: Empty query returns the full list

- **WHEN** an authenticated operator requests `GET /donors?q=`
- **THEN** the response renders the unfiltered first page of donors

### Requirement: Donor show page renders all stored fields

The application SHALL expose `GET /donors/:id` as an authenticated route that renders every stored donor field, including the names of the associated affiliate, category, courtesy title, and city/town (when present), plus links to edit and delete the donor.

#### Scenario: Show renders all fields and associations

- **GIVEN** a donor with `first_name = "Pat"`, `last_name = "Lee"`, `company = "Lee Holdings"`, `affiliate_id = 1` (BoissevainCC), `category_id = 4` (Individual), `courtesy_title_id = 6` (Mr.), and `city_town_id = nil`
- **WHEN** an authenticated operator requests `GET /donors/<that-id>`
- **THEN** the response body contains `Pat`, `Lee`, `Lee Holdings`, `BoissevainCC`, `Individual`, and `Mr.`
- **AND** the response body contains a link or control to edit at `/donors/<that-id>/edit`
- **AND** the response body contains a form that issues `DELETE /donors/<that-id>`

#### Scenario: Show handles nil city_town

- **GIVEN** a donor with `city_town_id = nil`
- **WHEN** an authenticated operator requests that donor's show page
- **THEN** the response renders successfully
- **AND** no exception is raised for the missing association

#### Scenario: Show renders legacy zip_code read-only when present

- **GIVEN** a donor with `zip_code = "55101"`
- **WHEN** an authenticated operator requests that donor's show page
- **THEN** the response body contains `55101`
- **AND** the response body does not contain a form input that edits `zip_code`

### Requirement: Donor new and create

The application SHALL expose `GET /donors/new` (renders a blank form) and `POST /donors` (submits the form, persists a new donor on success, re-renders the form with errors on validation failure) as authenticated routes covering every editable column on the `donors` table.

#### Scenario: New form renders with reference dropdowns

- **WHEN** an authenticated operator requests `GET /donors/new`
- **THEN** the response has HTTP status 200
- **AND** the response body contains a `<select>` for affiliate with one `<option>` per row in `affiliates`
- **AND** the response body contains a `<select>` for category with one `<option>` per row in `categories`
- **AND** the response body contains a `<select>` for courtesy_title with one `<option>` per row in `courtesy_titles`
- **AND** the response body contains a `<select>` for city_town that includes a blank option

#### Scenario: Create persists with valid params

- **GIVEN** valid reference IDs `affiliate_id = 1`, `category_id = 4`, `courtesy_title_id = 6`
- **WHEN** an authenticated operator submits `POST /donors` with `donor[first_name]=Pat`, `donor[last_name]=Lee`, `donor[affiliate_id]=1`, `donor[category_id]=4`, `donor[courtesy_title_id]=6`
- **THEN** a new `Donor` row is persisted with those values
- **AND** the response is a 302 redirect to that donor's show page

#### Scenario: Create re-renders with errors when the donor is not identifiable

- **WHEN** an authenticated operator submits `POST /donors` with all valid FKs but with only `first_name` set (no `last_name`, no `company`), or with only `last_name` set (no `first_name`, no `company`), or with all three blank
- **THEN** no `Donor` row is persisted
- **AND** the response has HTTP status 422 and re-renders the new form
- **AND** the response body contains a validation error indicating the donor must have both a first and last name, or a company

#### Scenario: Create form excludes the legacy zip_code field

- **WHEN** an authenticated operator requests `GET /donors/new`
- **THEN** the response body does not contain a form input named `donor[zip_code]`

### Requirement: Donor edit and update

The application SHALL expose `GET /donors/:id/edit` (renders the donor's form pre-filled) and `PATCH /donors/:id` (updates the record on success, re-renders the edit form with errors on validation failure) as authenticated routes covering the same editable fields as the new form.

#### Scenario: Edit form pre-fills existing values

- **GIVEN** a donor with `first_name = "Pat"` and `category_id = 4`
- **WHEN** an authenticated operator requests `GET /donors/<that-id>/edit`
- **THEN** the response body contains an input for `donor[first_name]` with value `Pat`
- **AND** the response body contains a `<select>` for category with the option for category id 4 marked selected

#### Scenario: Update persists valid changes

- **GIVEN** a donor with `last_name = "Lee"`
- **WHEN** an authenticated operator submits `PATCH /donors/<that-id>` with `donor[last_name]=Leigh`
- **THEN** that donor's `last_name` is updated to `Leigh`
- **AND** the response is a 302 redirect to that donor's show page

#### Scenario: Update re-renders with errors when invalid

- **GIVEN** a donor with `first_name = "Pat"`, `last_name = nil`, `company = nil`
- **WHEN** an authenticated operator submits `PATCH /donors/<that-id>` with `donor[first_name]=`
- **THEN** the donor record is not modified
- **AND** the response has HTTP status 422 and re-renders the edit form with the identification validation error

### Requirement: Donor destroy

The application SHALL expose `DELETE /donors/:id` as an authenticated route that deletes the donor and redirects to the index with a success flash. When the donor cannot be deleted because of dependent records the controller SHALL render the show page with an error flash instead of raising an unhandled exception.

#### Scenario: Destroy removes the donor

- **GIVEN** a donor exists
- **WHEN** an authenticated operator submits `DELETE /donors/<that-id>`
- **THEN** the donor row no longer exists in the database
- **AND** the response is a 302 redirect to `/donors`
- **AND** the flash contains a success message

#### Scenario: Destroy form is rendered with a confirm prompt

- **WHEN** an authenticated operator views any donor's show page
- **THEN** the page contains a destroy control (a form posting `DELETE` to `/donors/<that-id>`) annotated with a Turbo confirm attribute whose text mentions the action cannot be undone

#### Scenario: Destroy with dependent records is handled gracefully

- **GIVEN** a future capability has added a `restrict_with_exception` association from another model to this donor and the donor has at least one such dependent row
- **WHEN** an authenticated operator submits `DELETE /donors/<that-id>`
- **THEN** the donor row remains in the database
- **AND** the response renders the donor's show page (or redirects to it) with an error flash explaining the donor has dependent records
- **AND** the response status is not 500

### Requirement: Donor model validates identification

The `Donor` ActiveRecord model SHALL be invalid unless the record satisfies at least one of the following: `company` is present, OR both `first_name` AND `last_name` are present. The validation error SHALL be attached to `:base` with a message stating the donor must have both a first and last name, or a company.

#### Scenario: All three identifying fields blank is invalid

- **WHEN** `Donor.new(affiliate_id: 1, category_id: 4, courtesy_title_id: 6, first_name: nil, last_name: nil, company: nil).valid?` is called
- **THEN** the result is `false`
- **AND** `errors[:base]` contains a message indicating the donor must have both a first and last name, or a company

#### Scenario: Only a first name is not enough

- **WHEN** `Donor.new(affiliate_id: 1, category_id: 4, courtesy_title_id: 6, first_name: "Pat").valid?` is called
- **THEN** the result is `false`
- **AND** `errors[:base]` contains the identification error

#### Scenario: Only a last name is not enough

- **WHEN** `Donor.new(affiliate_id: 1, category_id: 4, courtesy_title_id: 6, last_name: "Lee").valid?` is called
- **THEN** the result is `false`
- **AND** `errors[:base]` contains the identification error

#### Scenario: First and last name together is sufficient

- **WHEN** `Donor.new(affiliate_id: 1, category_id: 4, courtesy_title_id: 6, first_name: "Pat", last_name: "Lee").valid?` is called
- **THEN** the result is `true`

#### Scenario: Company alone is sufficient

- **WHEN** `Donor.new(affiliate_id: 1, category_id: 4, courtesy_title_id: 6, company: "Acme Co").valid?` is called
- **THEN** the result is `true`
