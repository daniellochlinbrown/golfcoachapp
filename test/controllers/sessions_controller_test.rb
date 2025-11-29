require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get login page" do
    get login_path
    assert_response :success
  end

  test "should login with valid credentials" do
    user = users(:one)
    post login_path, params: { email: user.email, password: "password123" }
    assert_redirected_to root_path
  end

  test "should logout" do
    user = users(:one)
    log_in_as(user)
    delete logout_path
    assert_redirected_to root_path
  end
end
