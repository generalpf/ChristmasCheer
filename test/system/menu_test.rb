require "application_system_test_case"

class MenuTest < ApplicationSystemTestCase
  test "operator signs in and lands on the menu page with build footer" do
    user = users(:one)

    visit new_session_path
    fill_in "Enter your email address", with: user.email_address
    fill_in "Enter your password", with: "password"
    click_button "Sign in"

    assert_current_path root_path
    assert_selector "h1", text: "Christmas Cheer"
    assert_selector ".menu-item--placeholder", text: "future: donors"
    refute_selector "a", text: "future: donors"

    within "footer.app-footer" do
      assert_text "Build"
      refute_text "unknown"
      assert_selector "a.commit-sha"
      assert_link "GitHub", href: Rails.configuration.x.github_repo_url
    end
  end
end
