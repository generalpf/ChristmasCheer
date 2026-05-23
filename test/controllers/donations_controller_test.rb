require "test_helper"

class DonationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    @jane = donors(:jane_smith)
    @acme = donors(:acme_business)
    @donation = donations(:defaults_only)
  end

  # ---- auth ----

  test "GET /donations unauthenticated redirects to sign-in" do
    get donations_path
    assert_redirected_to new_session_path
  end

  # ---- index ----

  test "GET /donations authenticated returns 200 with a known donation row and link" do
    sign_in_as(@user)
    get donations_path
    assert_response :success
    assert_match "$25.00", response.body
    assert_select "a[href=?]", donation_path(@donation)
  end

  test "GET /donations orders by donation_date DESC NULLS LAST, id DESC" do
    sign_in_as(@user)
    get donations_path
    assert_response :success

    rows = css_select("table.donations-list tbody tr")
    date_cells = rows.map { |r| r.css("td").first.text.strip }
    # Fixture dates: 2025-05-10, 2025-04-01, 2025-03-15, 2025-01-05
    assert_equal %w[2025-05-10 2025-04-01 2025-03-15 2025-01-05], date_cells.first(4)
  end

  test "GET /donations paginates at 50 per page" do
    47.times do |i|
      Donation.create!(donor: @jane, amount: 1, donation_date: Date.new(2026, 1, 1) + i)
    end
    assert Donation.count > 50

    sign_in_as(@user)
    get donations_path, params: { page: 1 }
    assert_response :success
    page1_rows = css_select("table.donations-list tbody tr").length
    assert_operator page1_rows, :<=, 50
    assert_select "a[href=?]", donations_path(page: 2)
  end

  test "GET /donations?year=2025 filters by year" do
    Donation.create!(donor: @jane, amount: 7, donation_date: Date.new(2024, 6, 1))
    sign_in_as(@user)

    get donations_path, params: { year: 2025 }
    assert_response :success
    assert_match "$25.00", response.body
    assert_no_match(/\$7\.00/, response.body)
  end

  test "GET /donations renders year select with distinct years plus blank" do
    Donation.create!(donor: @jane, amount: 7, donation_date: Date.new(2024, 6, 1))
    Donation.create!(donor: @jane, amount: 8, donation_date: Date.new(2023, 6, 1))
    sign_in_as(@user)

    get donations_path
    assert_response :success
    assert_select "select[name=year]" do
      assert_select "option[value='']", count: 1
      assert_select "option[value='2025']"
      assert_select "option[value='2024']"
      assert_select "option[value='2023']"
    end
  end

  test "GET /donations?q=smit filters by donor last_name case-insensitively" do
    sign_in_as(@user)
    get donations_path, params: { q: "smit" }
    assert_response :success
    # Smith donations: $25.00 and $100.00
    assert_match "$25.00", response.body
    assert_match "$100.00", response.body
    # Acme donations should not appear
    assert_no_match(/\$500\.00/, response.body)
    assert_no_match(/\$1,000\.00/, response.body)
  end

  test "GET /donations?q=acme filters by donor company case-insensitively" do
    sign_in_as(@user)
    get donations_path, params: { q: "acme" }
    assert_response :success
    assert_match "$500.00", response.body
    assert_match "$1,000.00", response.body
    assert_no_match(/\$25\.00/, response.body)
  end

  test "GET /donations?year=2025&q=smit combines both filters" do
    Donation.create!(donor: @jane, amount: 7, donation_date: Date.new(2024, 6, 1))
    sign_in_as(@user)

    get donations_path, params: { year: 2025, q: "smit" }
    assert_response :success
    assert_match "$25.00",  response.body
    assert_match "$100.00", response.body
    assert_no_match(/\$7\.00/, response.body)
    assert_no_match(/\$500\.00/, response.body)
  end

  # ---- nested index ----

  test "GET /donors/:donor_id/donations scopes to that donor and omits q input" do
    sign_in_as(@user)
    get donor_donations_path(@jane)
    assert_response :success
    assert_match "$25.00", response.body
    assert_match "$100.00", response.body
    assert_no_match(/\$500\.00/, response.body)
    assert_no_match(/\$1,000\.00/, response.body)
    assert_no_match(/name=.q./, response.body)
  end

  test "GET /donors/9999/donations returns 404 when donor missing" do
    sign_in_as(@user)
    get donor_donations_path(9999)
    assert_response :not_found
  end

  # ---- show ----

  test "GET /donations/:id renders amount, donor link, booleans, and deferred FKs" do
    sign_in_as(@user)
    get donation_path(donations(:awaiting_receipt))
    assert_response :success
    assert_match "$500.00", response.body
    assert_select "a[href=?]", donor_path(@acme)
    # awaiting_receipt has required=true, pending=true, processed=false, replaced=false
    assert_match(/Receipt required.*yes/m, response.body)
    assert_match(/Receipt pending.*yes/m, response.body)
    assert_match(/Receipt processed.*no/m, response.body)
    assert_match(/Receipt replaced.*no/m, response.body)
    # No deferred FKs set on this one
    assert_match(/Source ID.*—/m, response.body)
    assert_match(/Payment ID.*—/m, response.body)
    assert_match(/Publication ID.*—/m, response.body)
  end

  # ---- new (top-level) ----

  test "GET /donations/new renders donor select and collapsed Advanced details" do
    sign_in_as(@user)
    get new_donation_path
    assert_response :success
    assert_select "select[name=?]", "donation[donor_id]"
    assert_select "details" do
      assert_select "summary", text: /Advanced/
      assert_select "input[name=?]", "donation[source_id]"
      assert_select "input[name=?]", "donation[payment_id]"
      assert_select "input[name=?]", "donation[publication_id]"
    end
    assert_no_match(/<details[^>]*\bopen\b/, response.body)
  end

  # ---- create (top-level) ----

  test "POST /donations with valid params persists and redirects to show" do
    sign_in_as(@user)
    assert_difference -> { Donation.count }, 1 do
      post donations_path, params: { donation: {
        donor_id: @jane.id,
        amount: "25.00",
        eligible_amount: "25.00",
        donation_date: "2025-03-15"
      } }
    end
    created = Donation.order(:id).last
    assert_redirected_to donation_path(created)
    assert_equal @jane.id, created.donor_id
    assert_equal 25.0, created.amount.to_f
  end

  test "POST /donations with no donor_id returns 422 with donor validation error" do
    sign_in_as(@user)
    assert_no_difference -> { Donation.count } do
      post donations_path, params: { donation: { amount: "25.00" } }
    end
    assert_response :unprocessable_entity
    assert_match(/Donor must exist/i, response.body)
  end

  # ---- nested new + create ----

  test "GET /donors/:donor_id/donations/new omits donor select" do
    sign_in_as(@user)
    get new_donor_donation_path(@jane)
    assert_response :success
    assert_no_match(/name=.donation\[donor_id\]./, response.body)
  end

  test "POST /donors/:donor_id/donations forces donor_id from URL" do
    sign_in_as(@user)
    assert_difference -> { Donation.count }, 1 do
      post donor_donations_path(@jane), params: { donation: {
        donor_id: @acme.id, # should be ignored — URL wins
        amount: "10.00"
      } }
    end
    created = Donation.order(:id).last
    assert_equal @jane.id, created.donor_id
    assert_redirected_to donation_path(created)
  end

  test "POST /donors/9999/donations returns 404 and persists nothing" do
    sign_in_as(@user)
    assert_no_difference -> { Donation.count } do
      post donor_donations_path(9999), params: { donation: { amount: "10.00" } }
    end
    assert_response :not_found
  end

  # ---- edit ----

  test "GET /donations/:id/edit pre-fills inputs and selects donor option" do
    sign_in_as(@user)
    donation = donations(:processed_with_receipt)
    get edit_donation_path(donation)
    assert_response :success
    assert_select "input[name=?][value=?]", "donation[amount]", "1000.00"
    assert_select "input[name=?][value=?]", "donation[receipt_num]", "R-2025-0042"
    assert_select "select[name=?]", "donation[donor_id]" do
      assert_select "option[selected=selected][value=?]", donation.donor_id.to_s
    end
  end

  test "GET /donations/:id/edit opens Advanced details when a deferred FK is set" do
    sign_in_as(@user)
    donation = donations(:bogus_deferred_fks)
    get edit_donation_path(donation)
    assert_response :success
    assert_match(/<details[^>]*\bopen\b/, response.body)
  end

  # ---- update ----

  test "PATCH /donations/:id with valid changes persists and redirects" do
    sign_in_as(@user)
    patch donation_path(@donation), params: { donation: { amount: "30.00" } }
    assert_redirected_to donation_path(@donation)
    assert_equal 30.0, @donation.reload.amount.to_f
  end

  test "PATCH /donations/:id with blank donor_id returns 422 without modifying" do
    sign_in_as(@user)
    original_amount = @donation.amount
    patch donation_path(@donation), params: { donation: { donor_id: "" } }
    assert_response :unprocessable_entity
    assert_match(/Donor must exist/i, response.body)
    assert_equal original_amount, @donation.reload.amount
  end

  # ---- destroy ----

  test "DELETE /donations/:id removes the donation and redirects to /donations" do
    sign_in_as(@user)
    target = Donation.create!(donor: @jane, amount: 5)
    assert_difference -> { Donation.count }, -1 do
      delete donation_path(target)
    end
    assert_redirected_to donations_path
    assert_match(/deleted/i, flash[:notice].to_s)
  end

  test "DELETE /donations/:id with referer to donor donations redirects there" do
    sign_in_as(@user)
    target = Donation.create!(donor: @jane, amount: 5)
    assert_difference -> { Donation.count }, -1 do
      delete donation_path(target),
        headers: { "HTTP_REFERER" => donor_donations_url(@jane) }
    end
    assert_redirected_to donor_donations_path(@jane)
  end

  # ---- menu page ----

  test "GET / contains link to /donations" do
    sign_in_as(@user)
    get root_path
    assert_response :success
    assert_select "a[href=?]", donations_path, text: "Donations"
  end
end
