require "test_helper"

class HandicapCalculationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    log_in_as(@user)
  end

  test "should redirect to golf rounds when no rounds in session" do
    get new_handicap_calculation_path
    assert_redirected_to new_golf_round_path
  end

  test "should redirect on create" do
    post handicap_calculations_path
    assert_redirected_to new_handicap_calculation_path
  end
end
