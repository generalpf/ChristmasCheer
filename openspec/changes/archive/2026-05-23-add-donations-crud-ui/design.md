## Context

The `donations` table just landed (commit `6f6656f`): `belongs_to :donor` (NOT NULL FK), money columns as `decimal(12,2)`, four `receipt_*` booleans, plus `source_id` / `payment_id` / `publication_id` shipped as nullable bigints with no FK constraints — those targets are not yet known. `Donor` declares `has_many :donations, dependent: :restrict_with_exception`, which the just-merged `DonorsController#destroy` already rescues.

The Donor CRUD UI from the previous change is the template: top-level `resources :donors`, a single REST controller with the seven standard actions, inline LIMIT/OFFSET pagination at 50 per page, `collection_select` for FK pickers, `button_to ... method: :delete` with a Turbo confirm, and views in `app/views/donors/{index,show,new,edit,_form}.html.erb`. The omakase `Authentication` concern is enforced at `ApplicationController`, so any new controller is operator-only by default. The auth-only home page (`HomeController#show`) is the menu; it currently lists only `Donors`.

There are no payment / source / publication reference tables yet, so the deferred-FK ints have to be raw integer inputs for now. A future change will swap them for selects once those tables exist.

## Goals / Non-Goals

**Goals:**
- A complete RESTful UI for `donations` reachable from the menu and from each donor's show page.
- Two index entry points: a top-level `/donations` list (all donations, with filter/search), and a per-donor `/donors/:donor_id/donations` list (only that donor's donations, no donor column).
- Create-from-donor flow: starting on a donor's show page, the operator can record a donation without re-selecting the donor.
- Year filter and donor keyword search on the top-level index; year-filter only on the nested index (donor is already fixed).
- Form covers every editable column. Deferred-FK ints (`source_id`, `payment_id`, `publication_id`) are visible but tucked into an "Advanced" `<details>` block so the routine flow stays clean.
- Validation errors come back inline; FK violations on a bogus `donor_id` cannot happen because the donor is always supplied (URL nest or `<select>` from the live donors table).
- The menu page gains a `Donations` entry; the donor show page gains a "Donations for this donor" link and a "Record a new donation" link.

**Non-Goals:**
- Receipt generation, deposit batching, payment-method selection, CSV/PDF export — separate changes.
- Resolving what `source_id` / `payment_id` / `publication_id` point at. The columns stay nullable bigints; the form accepts raw integers; we'll add proper `<select>`s once the target tables exist.
- Inline donor creation from the donation form. If the donor doesn't exist, the operator goes to Donors first.
- Soft-delete or restore. `DELETE /donations/:id` is hard-delete, mirroring donor destroy.
- Bulk operations (mass receipt-mark, mass delete). One record at a time.
- A dedicated `/admin` namespace — there is still no public surface to namespace away from.
- Aggregations on the index (sum of donations this year, etc.). The operator can read the table; reporting is a separate capability.
- Currency localization or formatting beyond `number_to_currency` with the Rails default — there is one operator, in Canada, and the column type stores plain decimal.

## Decisions

### Decision: Top-level `resources :donations` plus a nested `only: %i[index new create]` under donors

The operator has two natural entry points: "show me all donations from 2025" (top-level) and "record a donation for the person whose page I'm already on" (nested). Both deserve real routes:

```ruby
resources :donations
resources :donors do
  resources :donations, only: %i[index new create]
end
```

The nested routes scope to a donor via `params[:donor_id]` and are used only for the listing-from-donor and create-from-donor flows. Show, edit, update, and destroy stay on the top-level URLs (`/donations/:id`, `/donations/:id/edit`, etc.) — there is no reason for the donor scope to appear in those URLs once we already have the donation's id.

Alternative considered: nested-only (no top-level `/donations`). Rejected — the year filter / donor keyword search workflow needs a global list; threading every donor URL through to view recent donations across the dataset would be painful.

Alternative considered: a separate `Donors::DonationsController` for the nested actions. Rejected — duplicates render logic and strong-params for ~no benefit at this scope. One `DonationsController` with a `before_action` that resolves an optional `@donor` is enough.

### Decision: Single `DonationsController` with the seven REST actions

Same shape as `DonorsController`. Strong params method `donation_params`. A `before_action :set_donor_from_nested_route` resolves `@donor = Donor.find(params[:donor_id])` only when the nested route fired; `index` and `new` use it to scope and pre-fill, and `create` uses it to force `donor_id` from the URL rather than trusting params. Reference dropdown loading isn't needed for donations themselves — only the top-level form's donor `<select>` loads `Donor.order(:last_name, :company)`.

No service object, no form object. If the create flow grows real logic later (compute eligible amount from receipt rules, auto-pick next `c_receipt_num`, etc.), revisit then.

### Decision: Index ordering, pagination, and filters

Default sort: `donation_date DESC NULLS LAST, id DESC`. Newest first; rows without a date (legacy imports) sink to the bottom in a stable order. Pagination is inline LIMIT/OFFSET at 50 per page — same pattern as `DonorsController`. No extracted helper yet; if a third index appears (e.g., receipts), pull a `Paginator` POJO at that point.

Filters on the top-level index:
- `year` — a `<select>` of distinct years derived from `donations.donation_date` (computed via `Donation.distinct.pluck("EXTRACT(YEAR FROM donation_date)::int")`, compacted and sorted descending). When set, the controller scopes to `donation_date >= Date.new(year, 1, 1) AND donation_date < Date.new(year+1, 1, 1)`. A `null` / "Any year" option (the blank value) leaves the scope unfiltered.
- `q` — case-insensitive `ILIKE '%q%'` against the joined donor's `last_name` or `company` (the same two columns the donor index already searches). Implemented with `joins(:donor).where("donors.last_name ILIKE :p OR donors.company ILIKE :p", p: pattern)`. At expected volume a sequential donor scan is fine; the existing donor indexes on `last_name` and `company` won't help a `%q%` pattern anyway.

Nested index (`/donors/:donor_id/donations`): same ordering and pagination, no donor search (the donor is fixed), keep the year filter for symmetry.

Alternative considered: a date-range picker (`from` / `to`). Rejected — at this dataset size year-bucketed thinking matches how the operator already files records ("the 2024 cheer drive"). If finer-grained range becomes useful, swap the year `<select>` for two date inputs; the controller scope barely changes.

Alternative considered: `pg_trgm` GIN index for the donor name `ILIKE`. Rejected for now; revisit if join-and-scan becomes measurable. Few-thousand-row donors plus a few-thousand-row donations table is firmly in seq-scan-is-fine territory.

### Decision: Donor is always supplied — never trusted from form params on the nested route

On `POST /donors/:donor_id/donations`, the controller does `Donation.new(donation_params.merge(donor: @donor))`. `donation_params` permits `donor_id` for the top-level form path, but the nested path always overwrites it from the URL. This prevents a stale or tampered form posting a different `donor_id` than the one the URL claims and keeps the create flow consistent regardless of which form rendered it.

On `POST /donations` (top-level), `donor_id` comes from `donation_params` (i.e. the `<select>`) and is required by the model's `belongs_to :donor`. A missing/invalid id surfaces as a model validation error and re-renders the form with `:unprocessable_entity` — never as a 500.

### Decision: Form layout — money, dates, FKs visible; deferred-FK ints in `<details>`

Visible fields (in this order on the form):
1. `donor_id` `<select>` — only rendered when not nested under a donor. When nested, the controller scope already pins the donor; the partial skips the select.
2. `amount` and `eligible_amount` — `f.number_field` with `step: 0.01, min: 0`. Defaults to `0` from the DB; the field shows `25.00` style values when present.
3. `donation_date`, `receipt_date`, `deposit_date` — `f.date_field`. All nullable.
4. `c_receipt_num` (integer) and `receipt_num` (string) — separate inputs; the integer goes through `f.number_field`, the string is `f.text_field`.
5. `transaction_reference` (e.g., "CHQ#4711") and `message` — text fields.
6. The four `receipt_*` booleans as a checkbox group. No client-side workflow enforcement (e.g., "required ⇒ pending") yet; the receipt-generation change owns that.
7. `notes` — `f.text_area`.
8. An `<details><summary>Advanced (source / payment / publication IDs)</summary>` block containing `source_id`, `payment_id`, `publication_id` as `f.number_field, min: 0, step: 1`. The summary text plus the label for each input makes it explicit these are raw IDs awaiting their reference tables.

The deferred-FK block is **always** rendered (not conditioned on whether the values are set), so the operator who needs to enter them can find them in the same place every time. Collapsed by default; if a record has any of the three set, the partial opens the `<details>` block (`open` attribute) so the existing values are immediately visible on edit.

Money values display via `number_to_currency(donation.amount, unit: "$")` on the show page and as `format("%.2f", donation.amount)` inside the input's `value=` for clean two-decimal display.

### Decision: Receipt booleans are plain checkboxes; no enforced state machine

The Access source treats `ReceiptRequired`, `ReceiptPending`, `ReceiptProcessed`, and `ReceiptReplaced` as four independent flags. Without the receipt-generation change, any "you set processed without required" rule we encoded here would be premature. We render four `f.check_box` calls under a `<fieldset>`, each labelled with the column name, and persist whatever the operator submits. The eventual receipt change will own the state-machine rules and the per-flag validations.

### Decision: Show page renders everything; cross-link to donor and back

The show page renders every stored field — including the four `receipt_*` flags as yes/no text, the three deferred-FK ints as raw numbers when set (and an em-dash when nil), and `notes` through `simple_format`. The header reads `"$<amount> to <donor display name>"`, e.g., `"$25.00 to Jane Smith"`, with the donor name a link to the donor's show page. Below the header the page exposes Edit, Delete (button_to with Turbo confirm), "Back to donations", and "Back to this donor's donations" (only when arrived via the nested index, but we can render both unconditionally — they're cheap).

Donor display: `donor.first_name + " " + donor.last_name` when both are present, otherwise `donor.company`, otherwise `"Donor ##{donor.id}"`. Pull this into a shared helper (`donor_display_name(donor)`) so the index, show, and donor-show pages all agree.

### Decision: Destroy is hard-delete with a Turbo confirm

`button_to "Delete", donation_path(@donation), method: :delete, data: { turbo_confirm: "Delete this donation? This cannot be undone." }`. Success redirects to either the nested donor donations index (when the request referred from there) or `/donations`. We detect referrer source by checking `request.referer.to_s.include?(donor_donations_path(@donation.donor))` — good enough; no need for a hidden form field.

There is no `restrict_with_exception` on donations from any other model in this change (donations have no `has_many` yet), so unlike the donor destroy path we don't need to rescue anything beyond the standard `ActiveRecord::RecordNotFound` Rails handles for us.

### Decision: Menu page modification

Add `<li><%= link_to "Donations", donations_path %></li>` to the menu after the existing Donors entry. The `app-menu` capability's current `Donors entry` requirement is unchanged; we add a new requirement `Donations entry links to the donations index` alongside it. We do not declare this as `MODIFIED` because no existing scenario changes — we're adding a parallel one.

### Decision: Donor show page additions

In `app/views/donors/show.html.erb`, append (below the existing edit/delete/back row):

```erb
<p>
  <%= link_to "Donations for this donor", donor_donations_path(@donor) %> |
  <%= link_to "Record a new donation", new_donor_donation_path(@donor) %>
</p>
```

This is a small UI change to the donor show view; it does not change the `donor-crud` spec's behavior contract (which says "renders all stored fields ... plus links to edit and delete the donor" — the cross-link is additive). We do not add a delta to `donor-crud` for this; if a future reader of the spec is surprised by the link, we can add a scenario then.

## Risks / Trade-offs

- **[Risk]** Joining `donors` for the `q` search on the top-level donations index causes a full table scan once both tables grow. **Mitigation**: at expected volume it is a non-issue; if it ever measurably slows the index, add a `pg_trgm` GIN index on `donors.last_name`/`donors.company` in a follow-up.
- **[Risk]** Raw integer inputs for `source_id` / `payment_id` / `publication_id` let the operator type anything. The DB will accept it (no FK constraint), and reconciling those numbers later — once we know what they're supposed to point at — could surface garbage. **Mitigation**: the inputs are inside a collapsed `<details>` block so the operator only sees them when they actively decide to fill one in; the labels make it clear they are raw IDs. If garbage becomes an actual problem before the FK targets land, add a `numericality: { only_integer: true, greater_than: 0 }` validation in a follow-up.
- **[Risk]** Destroy is irreversible and the data is the source of truth for charitable receipts. A misclick deletes a real donation row. **Mitigation**: Turbo confirm with explicit "This cannot be undone." text plus the standard DB backup story. If the operator wants a recoverable delete later, soft-delete is a separate change (likely paired with the receipt workflow, which has stronger reasons to never lose history).
- **[Risk]** No model-level validation that `eligible_amount <= amount`. The CRA rule for split receipts often makes them equal, but split-receipt scenarios are valid (and the legacy data has them). **Mitigation**: leave the constraint off until the receipt-generation change ships its own rules; that change has the domain knowledge for what's actually required.
- **[Trade-off]** Two index entry points (top-level + nested) doubles the index-related test surface. Acceptable: both paths share controller code; the tests differ only in scope and presence of the donor column / search box.
- **[Trade-off]** Year filter is computed by `pluck`-ing distinct years on every index render. At a few thousand rows this is fine; if it becomes hot, cache it for a request or two. We don't bother yet.

## Migration Plan

No data migration. Deployment is a normal code release:

1. Merge the change. Rails picks up the new routes, controller, views, and menu link on next boot.
2. No DB changes — the `donations` table already exists.
3. Rollback: revert the merge commit. The table stays; nothing persists on the data side that wasn't already valid before.

## Open Questions

- Should the top-level donations index expose a "filter by deposit batch" once batches exist? Deferred — that capability isn't designed yet. The year filter is the only one we ship now.
- Once `source_id` / `payment_id` / `publication_id` get real reference tables, do those fields move out of the "Advanced" `<details>` and into the main form? Probably yes for any of them that become routine; design that with the change that creates the target tables.
