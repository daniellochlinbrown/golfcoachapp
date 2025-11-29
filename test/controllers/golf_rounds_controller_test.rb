require "test_helper"

class GolfRoundsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    log_in_as(@user)
  end

  test "should get new when logged in" do
    get new_golf_round_path
    assert_response :success
  end

  test "should redirect to login when not logged in" do
    delete logout_path
    get new_golf_round_path
    assert_redirected_to login_path
  end

  test "should get index when logged in" do
    get golf_rounds_path
    assert_response :success
  end
end
