require 'test_helper'

class OperationManagementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @operation_management = operation_managements(:one)
  end

  test "should get index" do
    get operation_managements_url, as: :json
    assert_response :success
  end

  test "should create operation_management" do
    assert_difference('OperationManagement.count') do
      post operation_managements_url, params: { operation_management: { created_by: @operation_management.created_by, deleted_at: @operation_management.deleted_at, load_unload_time: @operation_management.load_unload_time, operation_id: @operation_management.operation_id, operation_name: @operation_management.operation_name, part_configuration_id: @operation_management.part_configuration_id, part_per_cycle: @operation_management.part_per_cycle, process_plan_id: @operation_management.process_plan_id, setup_time: @operation_management.setup_time, status: @operation_management.status, std_cycle_time: @operation_management.std_cycle_time, tenant_id: @operation_management.tenant_id } }, as: :json
    end

    assert_response 201
  end

  test "should show operation_management" do
    get operation_management_url(@operation_management), as: :json
    assert_response :success
  end

  test "should update operation_management" do
    patch operation_management_url(@operation_management), params: { operation_management: { created_by: @operation_management.created_by, deleted_at: @operation_management.deleted_at, load_unload_time: @operation_management.load_unload_time, operation_id: @operation_management.operation_id, operation_name: @operation_management.operation_name, part_configuration_id: @operation_management.part_configuration_id, part_per_cycle: @operation_management.part_per_cycle, process_plan_id: @operation_management.process_plan_id, setup_time: @operation_management.setup_time, status: @operation_management.status, std_cycle_time: @operation_management.std_cycle_time, tenant_id: @operation_management.tenant_id } }, as: :json
    assert_response 200
  end

  test "should destroy operation_management" do
    assert_difference('OperationManagement.count', -1) do
      delete operation_management_url(@operation_management), as: :json
    end

    assert_response 204
  end
end
