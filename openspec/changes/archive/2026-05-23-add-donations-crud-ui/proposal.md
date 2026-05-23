## Why

The `donations` table now exists with model + FK constraints, but there is no way to view, add, edit, or delete a donation through the web app. The operator still has to drop into `rails console` (or the legacy Access database) to record a gift. Until donations CRUD lands, the new table is invisible to the only person who would use it.

## What Changes

- Add a full CRUD surface for donations under `/donations`:
  - `GET /donations` — list all donations with newest `donation_date` first, a year filter (drawn from the actual date range), and a donor name/company keyword search.
  - `GET /donations/:id` — show every stored field, including the donor's name/company and the `receipt_*` boolean state.
  - `GET /donations/new` and `POST /donations` — create form. When reached at the top level the donor is chosen from a `<select>`; when reached nested under a donor the donor is pre-set and hidden.
  - `GET /donations/:id/edit` and `PATCH /donations/:id` — edit form with the same fields as new.
  - `DELETE /donations/:id` — destroy with a Turbo confirm prompt.
- Add a nested read path: `GET /donors/:donor_id/donations` lists that donor's donations, and `GET /donors/:donor_id/donations/new` and `POST /donors/:donor_id/donations` create a donation pre-scoped to that donor (no donor select rendered, donor pulled from the URL — not from form params).
- Render the deferred-FK integer columns (`source_id`, `payment_id`, `publication_id`) as plain `<input type="number">` fields hidden inside an "Advanced" `<details>` block so they do not clutter the main form. Labels acknowledge they are raw IDs until those reference tables exist.
- Render the four `receipt_*` booleans as plain checkboxes (no workflow logic yet — that arrives with the receipt-generation change).
- Surface the new donations index from the menu page: add a `Donations` entry next to `Donors`.
- Cross-link from a donor's show page to that donor's nested donations list and a "New donation for this donor" link.
- No receipt generation, no deposit batching, no PDF/CSV export, no payment-method dropdown — those are separate changes.

## Capabilities

### New Capabilities
- `donation-crud`: HTTP surface and view layer for listing, searching, filtering, viewing, creating, editing, and deleting donation records, including the nested-under-donor variants of index, new, and create.

### Modified Capabilities
- `app-menu`: Add a `Donations` entry to the authenticated menu alongside the existing `Donors` entry.

## Impact

- Adds `app/controllers/donations_controller.rb` and `app/views/donations/{index,show,new,edit,_form,_row}.html.erb`.
- Edits `config/routes.rb` to declare `resources :donations` at the top level and to nest `resources :donations, only: %i[index new create]` under `resources :donors`.
- Edits `app/views/home/show.html.erb` to add a Donations menu entry (modifies `app-menu` capability).
- Edits `app/views/donors/show.html.erb` to add a "Donations for this donor" link and a "New donation for this donor" link.
- Adds controller, system, and small model tests covering search, year filter, nested create scoping, advanced FK inputs, and delete.
- No schema changes, no new gems, no auth changes. Reuses the inline pagination pattern from `DonorsController`.
