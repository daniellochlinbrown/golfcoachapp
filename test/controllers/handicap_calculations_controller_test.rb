require "test_helper"

class HandicapCalculationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get handicap_calculations_new_url
    assert_response :success
  end

  test "should get create" do
    get handicap_calculations_create_url
    assert_response :success
  end

  test "should get show" do
    get handicap_calculations_show_url
    assert_response :success
  end
end
