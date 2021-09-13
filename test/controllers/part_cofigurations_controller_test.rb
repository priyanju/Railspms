require 'test_helper'

class PartCofigurationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @part_cofiguration = part_cofigurations(:one)
  end

  test "should get index" do
    get part_cofigurations_url, as: :json
    assert_response :success
  end

  test "should create part_cofiguration" do
    assert_difference('PartCofiguration.count') do
      post part_cofigurations_url, params: { part_cofiguration: { customer_name: @part_cofiguration.customer_name, is_active: @part_cofiguration.is_active, part_description: @part_cofiguration.part_description, part_name: @part_cofiguration.part_name, part_number: @part_cofiguration.part_number, references: @part_cofiguration.references, role_id: @part_cofiguration.role_id } }, as: :json
    end

    assert_response 201
  end

  test "should show part_cofiguration" do
    get part_cofiguration_url(@part_cofiguration), as: :json
    assert_response :success
  end

  test "should update part_cofiguration" do
    patch part_cofiguration_url(@part_cofiguration), params: { part_cofiguration: { customer_name: @part_cofiguration.customer_name, is_active: @part_cofiguration.is_active, part_description: @part_cofiguration.part_description, part_name: @part_cofiguration.part_name, part_number: @part_cofiguration.part_number, references: @part_cofiguration.references, role_id: @part_cofiguration.role_id } }, as: :json
    assert_response 200
  end

  test "should destroy part_cofiguration" do
    assert_difference('PartCofiguration.count', -1) do
      delete part_cofiguration_url(@part_cofiguration), as: :json
    end

    assert_response 204
  end
end
