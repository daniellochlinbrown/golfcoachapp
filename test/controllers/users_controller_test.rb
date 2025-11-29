require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get signup page" do
    get signup_path
    assert_response :success
  end

  test "should create user with valid params" do
    assert_difference("User.count", 1) do
      post signup_path, params: { user: { email: "newuser@example.com", password: "password123", password_confirmation: "password123" } }
    end
    assert_redirected_to root_path
  end
end
