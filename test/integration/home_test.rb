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
