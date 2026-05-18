## 1. Routing and model validation

- [x] 1.1 Add `resources :donors` to `config/routes.rb`.
- [x] 1.2 Add the identification validation to `app/models/donor.rb`: invalid unless `company` is present, OR both `first_name` AND `last_name` are present; attach the error to `:base` with the message `"must have both a first and last name, or a company"`. Confirm the existing `belongs_to` associations already enforce presence for the three required FKs.
- [x] 1.3 Add `Donor` model tests covering: all-three-blank invalid; first-name-only invalid; last-name-only invalid; first+last valid; company-alone valid; an existing valid donor stays valid after the change.

## 2. DonorsController and views

- [x] 2.1 Generate / hand-write `app/controllers/donors_controller.rb` with the seven REST actions. Authentication comes from `ApplicationController`; no `allow_unauthenticated_access` calls.
- [x] 2.2 In `index`, build the query: apply `ILIKE '%q%'` on `last_name` OR `company` when `params[:q]` is present and non-blank; order by `last_name ASC NULLS LAST, company ASC NULLS LAST, id ASC`; eager-load `:affiliate`, `:category`, `:courtesy_title`, `:city_town`; paginate at 50 per page via a small `params[:page]`-driven `limit`/`offset` calculation. Expose `@donors`, `@page`, `@total_pages`, `@q`.
- [x] 2.3 In `new`, `create`, `edit`, `update`, populate `@affiliates`, `@categories`, `@courtesy_titles`, `@city_towns` sorted by their display column (`name` for the first two and city_towns, `title` for courtesy_titles).
- [x] 2.4 Implement `donor_params` whitelisting every editable column: `affiliate_id`, `category_id`, `courtesy_title_id`, `city_town_id`, `first_name`, `spouse`, `last_name`, `job_title`, `company`, `address_line1`, `address_line2`, `province`, `postal_code`, `phone`, `email1`, `email2`, `notes`. Deliberately exclude `zip_code`.
- [x] 2.5 In `create` / `update`, on validation failure re-render `new` / `edit` with status `:unprocessable_entity` after repopulating the reference collections; on success redirect to the donor's show page with a flash.
- [x] 2.6 In `destroy`, rescue `ActiveRecord::DeleteRestrictionError`, set an error flash explaining dependent records, and redirect to the donor's show page. On success, redirect to `donors_path` with a success flash.
- [x] 2.7 Create `app/views/donors/index.html.erb`: heading, search form (`<form method="get">` with a single `q` input and a submit button), donor table or list with last name / first name / company / city-town columns, a "New donor" link to `new_donor_path`, and pagination controls (Previous / `page X of Y` / Next, suppressing the link when at the boundary).
- [x] 2.8 Create `app/views/donors/show.html.erb`: render every stored field (including read-only `zip_code` when present), the associated reference names (`affiliate.name`, `category.name`, `courtesy_title.title`, `city_town&.name`), an Edit link, a Delete `button_to` with Turbo `data-turbo-confirm="Delete this donor? This cannot be undone."`, and a back link to the index.
- [x] 2.9 Create `app/views/donors/_form.html.erb` partial used by both `new` and `edit`: render `form.collection_select` for the four reference FKs (city_town with `include_blank: true`); render text inputs for the remaining writable columns; render `donor.errors[:base]` and field-level errors near the top.
- [x] 2.10 Create thin `app/views/donors/new.html.erb` and `app/views/donors/edit.html.erb` that render the shared `_form` partial.

## 3. Menu page update

- [x] 3.1 In `app/views/home/show.html.erb`, replace the disabled `future: donors` `<span>` with a `link_to "Donors", donors_path` inside the existing `<li>`. Remove the placeholder CSS class if it would no longer apply.

## 4. Tests

- [x] 4.1 Controller test: `GET /donors` while unauthenticated redirects to sign-in.
- [x] 4.2 Controller test: `GET /donors` while authenticated returns 200 and includes a known donor's last name + a link to `/donors/<id>`.
- [x] 4.3 Controller test: `GET /donors?q=<substring>` filters the list by last_name OR company case-insensitively; an empty `q` returns the full first page.
- [x] 4.4 Controller test: index paginates — given >50 fixture donors, `?page=1` renders 50 and exposes a link/control to `?page=2`.
- [x] 4.5 Controller test: `GET /donors/:id` renders all fields and association names; handles `city_town_id = nil` without exception; renders `zip_code` text when set but no input for it.
- [x] 4.6 Controller test: `GET /donors/new` renders the form and includes options for every seeded reference row; the city_town select has a blank option; the form has no `donor[zip_code]` input.
- [x] 4.7 Controller test: `POST /donors` with valid params persists and redirects to show; with only a first name (no last name, no company) returns 422 and re-renders with the `:base` identification error.
- [x] 4.8 Controller test: `GET /donors/:id/edit` pre-fills inputs and marks the correct reference options as selected.
- [x] 4.9 Controller test: `PATCH /donors/:id` with valid changes persists and redirects to show; blanking the donor's last name on a previously-individual record (leaving only first name) returns 422 without modifying the record.
- [x] 4.10 Controller test: `DELETE /donors/:id` removes the donor, redirects to `/donors`, and sets a success flash.
- [x] 4.11 Controller test: when destroy raises `ActiveRecord::DeleteRestrictionError` (stub or simulate), the donor is preserved, the response is 302 to the show page with an error flash, and the response status is not 500.
- [x] 4.12 Controller test: `GET /` (menu page) contains a link with `href="/donors"` and visible text `Donors`, and no `future: donors` placeholder text.
- [x] 4.13 System test: sign in, click Donors, search for a known last name, open a donor, edit a field, save, and confirm the change appears on the show page.
- [x] 4.14 System test: sign in, click Donors, click New, submit empty form, see the identification validation error inline; fill in both a first and last name (or a company) and submit again to succeed.

## 5. Verify

- [x] 5.1 Run `bin/rails test` and `bin/rails test:system`; all pass.
- [x] 5.2 Boot `bin/rails server`, sign in, exercise the index search, create, edit, and delete flows in the browser, and confirm flashes render and Turbo confirm prompts on delete.
- [x] 5.3 Run `bin/rubocop` and resolve any new offenses introduced by the change.
- [x] 5.4 Run `openspec validate add-donor-crud --strict` and `openspec status --change add-donor-crud`; all artifacts report done.
