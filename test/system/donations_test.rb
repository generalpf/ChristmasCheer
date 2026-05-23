require "application_system_test_case"

class DonationsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @jane = donors(:jane_smith)
    visit new_session_path
    fill_in "Enter your email address", with: @user.email_address
    fill_in "Enter your password", with: "password"
    click_button "Sign in"
    assert_current_path root_path
  end

  test "operator filters donations by year and opens a donation" do
    visit donations_path
    assert_selector "h1", text: "Donations"

    select "2025", from: "Year"
    click_button "Filter"
    assert_text "$25.00"

    visit donation_path(donations(:awaiting_receipt))
    assert_selector "h1", text: "$500.00"
    assert_text "Acme Widgets Ltd."
  end

  test "operator records a new donation from a donor's nested form" do
    visit new_donor_donation_path(@jane)
    assert_selector "h1", text: /New donation for/
    # Donor select should NOT render in the nested form
    assert_no_selector "select[name='donation[donor_id]']"

    find_field("Amount").set("17.50")
    find_field("Eligible amount").set("17.50")
    click_button "Create Donation"

    assert_text "Donation recorded.", wait: 5
    assert_text "$17.50"
  end
end
