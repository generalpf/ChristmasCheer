require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "GET / renders the placeholder home page" do
    get root_url
    assert_response :success
    assert_select "h1", text: "Brandon-Westman Christmas Cheer"
    assert_match(/Coming soon/i, response.body)
  end

  test "GET / does not require authentication" do
    get root_url
    assert_response :success
    assert_no_match(/redirect/i, response.headers["Location"].to_s)
  end
end
