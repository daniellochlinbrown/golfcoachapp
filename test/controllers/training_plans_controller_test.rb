require "test_helper"

class TrainingPlansControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get training_plans_new_url
    assert_response :success
  end

  test "should get create" do
    get training_plans_create_url
    assert_response :success
  end

  test "should get show" do
    get training_plans_show_url
    assert_response :success
  end

  test "should get index" do
    get training_plans_index_url
    assert_response :success
  end
end
