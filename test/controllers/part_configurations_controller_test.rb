require 'test_helper'

class PartConfigurationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @part_configuration = part_configurations(:one)
  end

  test "should get index" do
    get part_configurations_url, as: :json
    assert_response :success
  end

  test "should create part_configuration" do
    assert_difference('PartConfiguration.count') do
      post part_configurations_url, params: { part_configuration: { customer_name: @part_configuration.customer_name, is_active: @part_configuration.is_active, part_description: @part_configuration.part_description, part_name: @part_configuration.part_name, part_number: @part_configuration.part_number, role_id: @part_configuration.role_id, tenant_id: @part_configuration.tenant_id } }, as: :json
    end

    assert_response 201
  end

  test "should show part_configuration" do
    get part_configuration_url(@part_configuration), as: :json
    assert_response :success
  end

  test "should update part_configuration" do
    patch part_configuration_url(@part_configuration), params: { part_configuration: { customer_name: @part_configuration.customer_name, is_active: @part_configuration.is_active, part_description: @part_configuration.part_description, part_name: @part_configuration.part_name, part_number: @part_configuration.part_number, role_id: @part_configuration.role_id, tenant_id: @part_configuration.tenant_id } }, as: :json
    assert_response 200
  end

  test "should destroy part_configuration" do
    assert_difference('PartConfiguration.count', -1) do
      delete part_configuration_url(@part_configuration), as: :json
    end

    assert_response 204
  end
end
