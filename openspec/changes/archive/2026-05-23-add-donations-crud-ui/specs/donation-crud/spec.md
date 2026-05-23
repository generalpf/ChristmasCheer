## ADDED Requirements

### Requirement: Authenticated top-level donations index

The application SHALL expose `GET /donations` as an authenticated route that renders an HTML list of donation records ordered by `donation_date DESC NULLS LAST, id DESC`, paginated 50 rows per page, with each row showing the donation's amount, date, and the associated donor's display name as a link to the donation's show page.

#### Scenario: Unauthenticated request is redirected

- **WHEN** an unauthenticated client requests `GET /donations`
- **THEN** the response is a 302 redirect to the sign-in page
- **AND** no donation data appears in the response body

#### Scenario: Authenticated index renders donations newest first

- **GIVEN** donations exist with `donation_date = 2025-01-05`, `donation_date = 2025-05-10`, and `donation_date = nil`
- **WHEN** an authenticated operator requests `GET /donations?page=1`
- **THEN** the response has HTTP status 200
- **AND** the row for `2025-05-10` appears before the row for `2025-01-05`
- **AND** the row whose date is nil appears after both dated rows

#### Scenario: Each row links to the donation's show page

- **GIVEN** a donation with id 4 exists
- **WHEN** an authenticated operator requests `GET /donations`
- **THEN** the response body contains a hyperlink whose `href` is `/donations/4`

#### Scenario: Index paginates at 50 per page

- **GIVEN** 60 donations exist
- **WHEN** an authenticated operator requests `GET /donations?page=1`
- **THEN** the response body contains at most 50 donation rows
- **AND** the response body contains a link or control to navigate to `page=2`

### Requirement: Top-level donations index supports year and donor-name filters

The top-level donations index SHALL accept a `year` parameter and a `q` parameter. When `year` is present and parses to an integer, the index SHALL restrict the rendered list to donations whose `donation_date` falls in that calendar year. When `q` is present and non-blank, the index SHALL join `donors` and restrict the rendered list to donations whose donor's `last_name` OR `company` matches `q` case-insensitively as a substring (PostgreSQL `ILIKE '%q%'`). The two filters SHALL combine when both are supplied.

#### Scenario: Year filter restricts to that year

- **GIVEN** donations with `donation_date = 2025-03-15` and `donation_date = 2024-12-01` exist
- **WHEN** an authenticated operator requests `GET /donations?year=2025`
- **THEN** the response body contains the 2025 donation
- **AND** the response body does not contain the 2024 donation

#### Scenario: Year filter dropdown lists distinct years

- **GIVEN** donations with `donation_date` values spanning 2023, 2024, and 2025 exist
- **WHEN** an authenticated operator requests `GET /donations`
- **THEN** the response body contains a `<select name="year">` with one `<option>` per distinct year present in `donations.donation_date`
- **AND** the select includes a blank option representing "any year"

#### Scenario: Keyword search filters by donor last name

- **GIVEN** a donor with `last_name = "Smith"` has a donation and a donor with `last_name = "Jones"` has a donation
- **WHEN** an authenticated operator requests `GET /donations?q=smit`
- **THEN** the response body contains the Smith donation row
- **AND** the response body does not contain the Jones donation row

#### Scenario: Keyword search filters by donor company

- **GIVEN** a donor with `company = "Acme Industries"` has a donation
- **WHEN** an authenticated operator requests `GET /donations?q=acme`
- **THEN** the response body contains the Acme donation row

#### Scenario: Year and q combine

- **GIVEN** donor "Smith" has donations in 2024 and 2025, and donor "Jones" has a donation in 2025
- **WHEN** an authenticated operator requests `GET /donations?year=2025&q=smit`
- **THEN** the response body contains the Smith 2025 donation only

### Requirement: Authenticated per-donor donations index

The application SHALL expose `GET /donors/:donor_id/donations` as an authenticated route that renders an HTML list of donations belonging to the donor identified by `:donor_id`, using the same default ordering and pagination as the top-level index, without rendering the donor column (since every row belongs to the same donor) and without the donor-name search box (year filter is still rendered for symmetry).

#### Scenario: Nested index scopes to the donor

- **GIVEN** donor A has donations [a1, a2] and donor B has donation [b1]
- **WHEN** an authenticated operator requests `GET /donors/<A-id>/donations`
- **THEN** the response body contains a row for a1 and a row for a2
- **AND** the response body does not contain a row for b1

#### Scenario: Nested index does not render a donor-name search box

- **WHEN** an authenticated operator requests `GET /donors/<any-id>/donations`
- **THEN** the response body does not contain an `<input name="q">`

#### Scenario: Nested index links to the donor's show page

- **WHEN** an authenticated operator requests `GET /donors/<id>/donations`
- **THEN** the response body contains a link to `/donors/<id>` labelled with the donor's display name

#### Scenario: Nested index unknown donor returns 404

- **WHEN** an authenticated operator requests `GET /donors/9999/donations` and no donor with id 9999 exists
- **THEN** the response has HTTP status 404

### Requirement: Donation show page renders all stored fields

The application SHALL expose `GET /donations/:id` as an authenticated route that renders every stored donation field — including `amount` and `eligible_amount` formatted as currency, the three date fields, `c_receipt_num`, `receipt_num`, `transaction_reference`, `message`, the four `receipt_*` booleans rendered as yes/no text, the deferred-FK ints `source_id` / `payment_id` / `publication_id` rendered as raw integers (or em-dash when nil), and `notes` rendered via `simple_format` — plus a header showing the donor's display name as a link to that donor's show page, an Edit link, a Delete `button_to`, and back links.

#### Scenario: Show renders amount, donor link, and all four booleans

- **GIVEN** a donation with `amount = 25.00`, `donor_id` for a donor whose display name is `Jane Smith`, `receipt_required = true`, `receipt_pending = true`, `receipt_processed = false`, `receipt_replaced = false`
- **WHEN** an authenticated operator requests `GET /donations/<that-id>`
- **THEN** the response body contains `$25.00`
- **AND** the response body contains a link to `/donors/<donor-id>` with visible text `Jane Smith`
- **AND** the response body indicates `receipt_required` and `receipt_pending` are yes and `receipt_processed` and `receipt_replaced` are no

#### Scenario: Show renders deferred-FK ints when set and em-dash when nil

- **GIVEN** a donation with `source_id = 7`, `payment_id = nil`, `publication_id = nil`
- **WHEN** an authenticated operator requests its show page
- **THEN** the response body contains `7` rendered as the source id value
- **AND** the response body renders an em-dash (or equivalent placeholder) for `payment_id` and `publication_id`

#### Scenario: Show contains edit and delete controls

- **GIVEN** a donation exists
- **WHEN** an authenticated operator requests its show page
- **THEN** the response body contains a link to `/donations/<that-id>/edit`
- **AND** the response body contains a form that issues `DELETE /donations/<that-id>` annotated with a Turbo confirm attribute whose text indicates the action cannot be undone

### Requirement: Donation new and create (top-level)

The application SHALL expose `GET /donations/new` (renders a blank form including a donor `<select>`) and `POST /donations` (submits the form, persists a new donation on success, re-renders the form with errors on validation failure) as authenticated routes covering every editable column on the `donations` table. The form SHALL render `source_id`, `payment_id`, and `publication_id` as raw integer inputs inside a `<details>` element labelled `Advanced` so they are visible but collapsed by default.

#### Scenario: New form renders with a donor select

- **WHEN** an authenticated operator requests `GET /donations/new`
- **THEN** the response has HTTP status 200
- **AND** the response body contains a `<select name="donation[donor_id]">` with one `<option>` per row in `donors`

#### Scenario: New form puts deferred-FK ints in a collapsed Advanced block

- **WHEN** an authenticated operator requests `GET /donations/new`
- **THEN** the response body contains a `<details>` element whose summary text contains `Advanced`
- **AND** that `<details>` element contains inputs named `donation[source_id]`, `donation[payment_id]`, and `donation[publication_id]`
- **AND** that `<details>` element is not rendered with the `open` attribute

#### Scenario: Create persists with valid params

- **GIVEN** a donor with id `<D>` exists
- **WHEN** an authenticated operator submits `POST /donations` with `donation[donor_id]=<D>`, `donation[amount]=25.00`, `donation[eligible_amount]=25.00`, `donation[donation_date]=2025-03-15`
- **THEN** a new `Donation` row is persisted with those values
- **AND** the response is a 302 redirect to that donation's show page

#### Scenario: Create re-renders with errors when donor_id is missing

- **WHEN** an authenticated operator submits `POST /donations` with `donation[amount]=25.00` and no `donation[donor_id]`
- **THEN** no `Donation` row is persisted
- **AND** the response has HTTP status 422 and re-renders the new form
- **AND** the response body contains a validation error indicating donor must exist

### Requirement: Donation new and create (nested under donor)

The application SHALL expose `GET /donors/:donor_id/donations/new` (renders the donation form with no donor `<select>`, donor pre-set from the URL) and `POST /donors/:donor_id/donations` (persists the donation with `donor_id` taken from the URL, regardless of any `donor_id` value in form params) as authenticated routes.

#### Scenario: Nested new form omits the donor select

- **GIVEN** a donor with id `<D>` exists
- **WHEN** an authenticated operator requests `GET /donors/<D>/donations/new`
- **THEN** the response has HTTP status 200
- **AND** the response body does not contain a `<select name="donation[donor_id]">`

#### Scenario: Nested create forces donor_id from the URL

- **GIVEN** donors with ids `<D>` and `<OTHER>` both exist
- **WHEN** an authenticated operator submits `POST /donors/<D>/donations` with `donation[donor_id]=<OTHER>` and `donation[amount]=10.00`
- **THEN** the persisted donation has `donor_id = <D>` (not `<OTHER>`)
- **AND** the response is a 302 redirect to that donation's show page

#### Scenario: Nested create on unknown donor returns 404

- **WHEN** an authenticated operator submits `POST /donors/9999/donations` and no donor with id 9999 exists
- **THEN** the response has HTTP status 404
- **AND** no `Donation` row is persisted

### Requirement: Donation edit and update

The application SHALL expose `GET /donations/:id/edit` (renders the donation's form pre-filled, including a donor `<select>` so the operator can re-assign to a different donor) and `PATCH /donations/:id` (updates the record on success, re-renders the edit form with errors on validation failure) as authenticated routes covering the same editable fields as the top-level new form.

#### Scenario: Edit form pre-fills existing values

- **GIVEN** a donation with `amount = 1000.00`, `receipt_num = "R-2025-0042"`, `donor_id = <D>`
- **WHEN** an authenticated operator requests `GET /donations/<that-id>/edit`
- **THEN** the response body contains an input for `donation[amount]` with value `1000.00`
- **AND** the response body contains an input for `donation[receipt_num]` with value `R-2025-0042`
- **AND** the response body contains a `<select name="donation[donor_id]">` with the option for `<D>` marked selected

#### Scenario: Edit form opens the Advanced block when any deferred FK is set

- **GIVEN** a donation with `source_id = 9999` (and `payment_id` / `publication_id` nil)
- **WHEN** an authenticated operator requests `GET /donations/<that-id>/edit`
- **THEN** the response body contains a `<details>` element whose summary contains `Advanced`
- **AND** that `<details>` element is rendered with the `open` attribute

#### Scenario: Update persists valid changes

- **GIVEN** a donation with `amount = 25.00`
- **WHEN** an authenticated operator submits `PATCH /donations/<that-id>` with `donation[amount]=30.00`
- **THEN** that donation's `amount` is updated to `30.00`
- **AND** the response is a 302 redirect to that donation's show page

#### Scenario: Update re-renders with errors when invalid

- **GIVEN** a donation exists
- **WHEN** an authenticated operator submits `PATCH /donations/<that-id>` with `donation[donor_id]=` (blank)
- **THEN** the donation record is not modified
- **AND** the response has HTTP status 422 and re-renders the edit form with a donor validation error

### Requirement: Donation destroy

The application SHALL expose `DELETE /donations/:id` as an authenticated route that deletes the donation and redirects with a success flash. The redirect target SHALL be the per-donor donations index when the request was made from there (detected via referer), and the top-level donations index otherwise.

#### Scenario: Destroy removes the donation

- **GIVEN** a donation exists
- **WHEN** an authenticated operator submits `DELETE /donations/<that-id>`
- **THEN** the donation row no longer exists in the database
- **AND** the response is a 302 redirect to `/donations`
- **AND** the flash contains a success message

#### Scenario: Destroy redirects to the donor's donations index when called from there

- **GIVEN** a donation belonging to donor `<D>` exists
- **WHEN** an authenticated operator submits `DELETE /donations/<that-id>` with `Referer: /donors/<D>/donations`
- **THEN** the donation row no longer exists in the database
- **AND** the response is a 302 redirect to `/donors/<D>/donations`

#### Scenario: Destroy form is rendered with a confirm prompt

- **WHEN** an authenticated operator views any donation's show page
- **THEN** the page contains a destroy control (a form posting `DELETE` to `/donations/<id>`) annotated with a Turbo confirm attribute whose text mentions the action cannot be undone
