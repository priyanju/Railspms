require 'test_helper'

class OperatorAllotDetailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @operator_allot_detail = operator_allot_details(:one)
  end

  test "should get index" do
    get operator_allot_details_url, as: :json
    assert_response :success
  end

  test "should create operator_allot_detail" do
    assert_difference('OperatorAllotDetail.count') do
      post operator_allot_details_url, params: { operator_allot_detail: { end_time: @operator_allot_detail.end_time, operation_management_id: @operator_allot_detail.operation_management_id, operator_allocation_id: @operator_allot_detail.operator_allocation_id, operator_id: @operator_allot_detail.operator_id, start_time: @operator_allot_detail.start_time, tenant_id: @operator_allot_detail.tenant_id } }, as: :json
    end

    assert_response 201
  end

  test "should show operator_allot_detail" do
    get operator_allot_detail_url(@operator_allot_detail), as: :json
    assert_response :success
  end

  test "should update operator_allot_detail" do
    patch operator_allot_detail_url(@operator_allot_detail), params: { operator_allot_detail: { end_time: @operator_allot_detail.end_time, operation_management_id: @operator_allot_detail.operation_management_id, operator_allocation_id: @operator_allot_detail.operator_allocation_id, operator_id: @operator_allot_detail.operator_id, start_time: @operator_allot_detail.start_time, tenant_id: @operator_allot_detail.tenant_id } }, as: :json
    assert_response 200
  end

  test "should destroy operator_allot_detail" do
    assert_difference('OperatorAllotDetail.count', -1) do
      delete operator_allot_detail_url(@operator_allot_detail), as: :json
    end

    assert_response 204
  end
end
