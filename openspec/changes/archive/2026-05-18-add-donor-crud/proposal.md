## Why

The donors table, its reference tables, and the authenticated menu page all exist, but the menu still shows `future: donors` as a disabled placeholder — there is no way for the operator to view, add, edit, or delete a donor through the web app. Until donor CRUD lands, the Rails app is just a schema; the operator still has to use Access (or `rails console`) for every change.

## What Changes

- Replace the disabled `future: donors` menu entry on the authenticated home page with a real link to the donor index.
- Add a full CRUD surface for donors under `/donors`:
  - `GET /donors` — list with last-name/company keyword search, alphabetical default sort, simple pagination.
  - `GET /donors/:id` — show all fields of a single donor with edit/delete controls.
  - `GET /donors/new` and `POST /donors` — create form covering every column in the `donors` table.
  - `GET /donors/:id/edit` and `PATCH /donors/:id` — edit form with the same fields as new.
  - `DELETE /donors/:id` — destroy with a confirm prompt.
- Render the four reference FKs (`affiliate`, `category`, `courtesy_title`, `city_town`) as `<select>` dropdowns sourced from the reference tables. `city_town` includes a blank option (it is the only nullable FK).
- Add minimal model-level validation so the form gives actionable errors before hitting the DB constraints: `affiliate`, `category`, and `courtesy_title` required (already enforced by `belongs_to`); the donor must be identifiable — either both `first_name` AND `last_name` are present, or `company` is present.
- All donor routes require authentication (same `Authentication` concern the rest of the app uses).
- No CSV import/export, no donations UI, no bulk operations, no audit trail — those are separate changes.

## Capabilities

### New Capabilities
- `donor-crud`: HTTP surface and view layer for listing, searching, viewing, creating, editing, and deleting donor records, including the model-level validations that the create/edit forms surface.

### Modified Capabilities
- `app-menu`: The `future: donors` placeholder requirement is replaced with a real link to `GET /donors`. The footer requirements and the rest of the menu page are unchanged.

## Impact

- Adds `app/controllers/donors_controller.rb`, `app/views/donors/{index,show,new,edit,_form}.html.erb`, and a route `resources :donors` in `config/routes.rb`.
- Adds validations to `app/models/donor.rb` (donor must have both a first and last name, or a company; the FK presence is already implicit via `belongs_to`).
- Edits `app/views/home/show.html.erb` to swap the placeholder list item for a real menu link, and updates the `app-menu` spec accordingly.
- Adds controller, model, and system tests covering the search, validation, and delete flows.
- No new gems, no schema changes, no auth changes. Pagination is implemented inline (LIMIT/OFFSET) — no Kaminari/Pagy dependency for this volume of data.
