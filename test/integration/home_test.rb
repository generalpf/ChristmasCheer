require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "unauthenticated GET / redirects to sign-in" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "authenticated GET / returns 200" do
    sign_in_as users(:one)
    get root_path
    assert_response :success
    assert_select "h1", text: "Christmas Cheer"
  end

  test "authenticated GET / renders the menu with a donors link and a sign-out form" do
    sign_in_as users(:one)
    get root_path

    assert_response :success
    assert_select "a[href=?]", donors_path, text: "Donors"
    assert_no_match(/future: donors/, response.body)
    assert_select "form[action=?][method=?]", session_path, "post" do
      assert_select "input[name=_method][value=delete]"
    end
  end

  test "no public sign-up route exists" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users/new", method: :get)
    end
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users", method: :post)
    end
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/sign_up", method: :get)
    end
  end
end
