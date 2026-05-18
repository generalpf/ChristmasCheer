require "application_system_test_case"

class DonorsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    visit new_session_path
    fill_in "Enter your email address", with: @user.email_address
    fill_in "Enter your password", with: "password"
    click_button "Sign in"
  end

  test "operator searches, opens, edits, and saves a donor" do
    click_on "Donors"

    fill_in "Search last name or company", with: "Smith"
    click_on "Search"

    assert_text "Smith"
    click_on "View", match: :first

    click_on "Edit"
    fill_in "Last name", with: "Smyth"
    click_button "Update Donor"

    assert_text "Donor updated."
    assert_text "Smyth"
  end

  test "new donor form surfaces identification error then succeeds" do
    click_on "Donors"
    click_on "New donor"

    select "BoissevainCC", from: "Affiliate"
    select "Individual", from: "Category"
    select "Mr.", from: "Courtesy title"
    click_button "Create Donor"

    assert_text "must have both a first and last name, or a company"

    fill_in "First name", with: "Sam"
    fill_in "Last name", with: "Test"
    click_button "Create Donor"

    assert_text "Donor created."
    assert_text "Sam"
    assert_text "Test"
  end
end
