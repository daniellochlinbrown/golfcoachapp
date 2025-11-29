require "test_helper"

class GolfRoundsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get golf_rounds_new_url
    assert_response :success
  end

  test "should get create" do
    get golf_rounds_create_url
    assert_response :success
  end

  test "should get index" do
    get golf_rounds_index_url
    assert_response :success
  end
end
